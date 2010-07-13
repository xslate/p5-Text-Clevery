package Text::Clevy::Parser;
use Any::Moose;
extends 'Text::Xslate::Parser';

use Text::Xslate::Util qw(p any_in);

sub _build_identity_pattern { qr{ [/\$]? [a-zA-Z_][a-zA-Z0-9_]* }xms }

sub _build_line_start { undef  }
sub _build_tag_start  { '{' }
sub _build_tag_end    { '}' }

around trim_code => sub {
    my($super, $parser, $code) = @_;

    if($code =~ /\A \* .* \* \z/xms) { # comment
        return '';
    }
    elsif($code =~ /\A \# (.*) \# \z/xms) { # config
        return sprintf '$clevy.config.%s', $1;
    }

    return $super->($parser, $code);
};

around split => sub {
    my($super, $parser, @args) = @_;


    my $tokens_ref = $super->($parser, @args);
    for(my $i = 0; $i < @{$tokens_ref}; $i++) {
        my $t = $tokens_ref->[$i];
        if($t->[0] eq 'code' && $t->[1] =~ m{\A \s* literal \s* \z}xms) {
            my $text = '';

            for(my $j = $i + 1; $j < @{$tokens_ref}; $j++) {
                my $u = $tokens_ref->[$j];
                if($u->[0] eq 'code' && $u->[1] =~ m{\A \s* /literal \s* \z}xms) {
                    splice @{$tokens_ref}, $i+1, $j - $i;
                    last;
                }
                elsif( $u->[0] eq 'code' ) {
                    $text .= $parser->tag_start . $u->[1];

                    my $n = $tokens_ref->[$j+1];
                    if($n && $n->[0] eq 'postchomp') {
                        $text .= $n->[1];
                        $j++;
                    }
                    $text .= $parser->tag_end;
                }
                else {
                    $text .= $u->[1];
                }
            }
            $t->[0] = 'text';
            $t->[1] = $text;
        }
    }
    return $tokens_ref;
};

sub init_symbols {
    my($parser) = @_;

    $parser->init_basic_operators();

    $parser->symbol('`')->set_nud(\&nud_backquote);

    $parser->symbol('(name)')->set_std(\&std_name);

    $parser->symbol('|')     ->set_led(\&led_pipe);

    $parser->symbol('$clevy') ->set_nud(\&nud_clevy_context);
    $parser->symbol('$smarty')->set_nud(\&nud_clevy_context);

    $parser->symbol('if')    ->set_std(\&std_if);
    $parser->symbol('elseif')->is_block_end(1);
    $parser->symbol('else')  ->is_block_end(1);

    $parser->symbol('foreach')->set_std(\&std_foreach);
    $parser->symbol('foreachelse')->is_block_end(1);

    $parser->symbol('/if')      ->is_block_end(1);
    $parser->symbol('/foreach') ->is_block_end(1);

    return;
}

sub nud_backquote { # the same as parens
    my($parser, $symbol) = @_;
    my $expr = $parser->expression(0);
    $parser->advance('`');
    return $expr;
}

sub nud_clevy_context {
    my($parser, $symbol) = @_;
    return $parser->call('@clevy_context');
}

# variable modifiers
# expr | modifier : param1 : param2 ...
sub led_pipe {
    my($parser, $symbol, $left) = @_;

    my $bar = $parser->SUPER::led_pipe($symbol, $left);

    my @args;
    while($parser->token->id eq ':') {
        $parser->advance();
        my $modifier = $parser->expression(0);
        push @args, $modifier;
    }
    push @{$bar->second}, @args;
    return $bar;
}

sub attr_list {
    my($parser) = @_;
    my @args;
    while(1) {
        my $key = $parser->token;

        if($key->arity ne "name") {
            last;
        }
        $parser->advance();
        $parser->advance("=");

        my $value;
        if($parser->token->arity eq "name") {
            $value = $parser->token->clone(arity => 'literal');
            $parser->advance();
        }
        else {
            $value = $parser->expression(0);
        }

        push @args, $key->clone(arity => 'literal') => $value;
    }

    return @args;
}

sub std_name {
    my($parser, $symbol) = @_;

    my @args = $parser->attr_list();
    return $parser->symbol('print')->clone(
        arity => 'command',
        first => [$parser->call($symbol, @args)],
    );
}

sub define_function {
    my($parser, @names) = @_;

    foreach my $name(@names) {
        my $s = $parser->symbol($name);
        $s->set_std(\&std_name);
    }
    return;
}


sub std_if {
    my($parser, $symbol) = @_;

    my $if = $symbol->clone(arity => 'if');

    $if->first( $parser->expression(0) );
    $if->second( $parser->statements() );

    my $t = $parser->token;

    my $top_if = $if;

    while($t->id eq 'elseif') {
        $parser->reserve($t);
        $parser->advance();

        my $elsif = $t->clone(arity => "if");
        $elsif->first(  $parser->expression(0) );
        $elsif->second( $parser->statements() );
        $if->third([$elsif]);
        $if = $elsif;
        $t  = $parser->token;
    }

    if($t->id eq 'else') {
        $parser->reserve($t);
        $parser->advance();

        $if->third( $parser->statements() );
    }

    $parser->advance('/if');

    return $top_if;
}

sub std_foreach {
    my($parser, $symbol) = @_;

    my $for = $symbol->clone( arity => 'for' );

    my %args = $parser->attr_list();

    my $from = $args{from} or $parser->_error("You must specify 'from' attribute for {foreach}");
    my $item = $args{item} or $parser->_error("You must specify 'item' attribute for {foreach}");
    my $key  = $args{key};
    my $name = $args{name};

    $item->id( '$' . $item->id );
    $item->arity('variable');

    $for->first($from);
    $for->second([$item]);

    $parser->new_scope();
    my $iterator = $parser->define_iterator($item);
    my $body = $parser->statements();
    $parser->pop_scope();

    # set_foreach_property(name, $~iter.index, $~iter.body)
    if($name) {
        unshift @{$body}, $parser->call(
            '@clevy_set_foreach_property',
            $name,
            $iterator,
            $parser->iterator_body($iterator),
        );
    }
    $for->third($body);

    if($parser->token->id eq 'foreachelse') {
        $parser->advance();

        # if array_is_empty(my $array = expr) {
        #    foreach expr -> ...
        # }
        # else {
        #    foreachelse ...
        # }

        my $else = $parser->statements();

        my $tmpname = $parser->symbol('($foreach)')->clone(arity => 'name');
        my $tmpinit = $symbol->clone(
            arity        => 'constant',
            first        => $tmpname,
            second       => $from,
        );
        $for->first($tmpname);

        my $array_is_not_empty = $parser->call(
            '@clevy_array_is_not_empty', $tmpinit);

        my $if = $symbol->clone(
            arity  => 'if',
            first  => $array_is_not_empty,
            second => [$for],
            third  => $else,
       );

       $for = $if;
    }

    $parser->advance('/foreach');

    if(defined $key) {
        $for = $parser->_not_implemented($symbol,
            "'key' attribute for {foreach}");
    }

    return $for;
}

sub _not_implemented {
    my($self, $proto, $name) = @_;
    return $self->call('@clevy_not_implemented',
        $proto->clone(arity => 'literal', value => $name));
}

no Any::Moose;
1;
