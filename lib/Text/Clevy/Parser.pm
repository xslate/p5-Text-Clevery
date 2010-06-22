package Text::Clevy::Parser;
use Any::Moose;
extends 'Text::Xslate::Parser';

use Text::Xslate::Util qw(p any_in);

sub _build_line_start { undef  }
sub _build_tag_start  { qr/\{/ }
sub _build_tag_end    { qr/\}/ }

around trim_code => sub {
    my($super, $parser, $code) = @_;

    if($code =~ /\A \* .* \* \z/xms) { # comment
        return '';
    }
    elsif($code =~ /\A \# (.*) \# \z/xms) { # config
        return sprintf '$smarty.config.%s', $1;
    }

    return $super->($parser, $code);
};


sub init_symbols {
    my($parser) = @_;

    $parser->init_basic_operators();

    $parser->symbol('if')    ->set_std(\&std_if);
    $parser->symbol('elseif')->is_block_end(1);
    $parser->symbol('else')  ->is_block_end(1);

    $parser->symbol('/')     ->is_block_end(1); # {/if}

    $parser->symbol('$smarty')->set_nud(\&nud_smarty);

    return;
}

sub nud_smarty {
    my($parser, $symbol) = @_;

    # $smarty -> __smarty__()
    return $symbol->clone(
        arity  => 'call',
        first  => $symbol->clone(id => '__smarty__', arity => 'name'),
        second => [],
    );
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

    $parser->advance('/');
    $parser->advance('if');

    return $top_if;
}

no Any::Moose;
1;
