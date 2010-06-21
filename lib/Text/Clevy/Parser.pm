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

    $parser->symbol('if')     ->set_std(\&std_if);
    $parser->symbol('else')->is_block_end(1);

    $parser->symbol('/')->is_block_end(1); # {/if}

    return;
}

sub std_if {
    my($parser, $symbol) = @_;

    my $if = $symbol->clone(arity => 'if');

    $if->first( $parser->expression(0) );
    $if->second( $parser->statements() );

    my $t = $parser->token;
    if($parser->token->id eq 'else') {
        $parser->reserve($t);
        $parser->advance();

        $if->third( $parser->statements() );
    }

    $parser->advance('/');
    $parser->advance('if');

    return $if;
}

no Any::Moose;
1;
