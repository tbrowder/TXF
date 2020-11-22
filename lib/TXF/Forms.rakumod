unit module TXF::Forms;

class Form-actions {
}

grammar Form-grammar {

    # this parses fine and ready for actions
    token TOP {
        <line>+
    }

    token line          { [<end-of-record> || <field> || <blank>] }
    token field         { $<code>=. $<value>=\N* \n }
    token end-of-record { '^' \n }
    token blank         { \h* \n }

    =begin comment
    # tokens below are unused at the moment

    # a header is a collection of the three header fields in a 
    # specific order possibly interspersed with blank lines
    token header {
        <header-field>+
    }

    # a record is a certain collection of fields possibly interspersed
    # with blank lines
    token record {
        <record-field>?
    }
    =end comment 
}


class Box is export {
    # must define all three:
    has $.id;
    has $.llx;
    has $.lly;

    # must define one of the two:
    has $.urx;
    has $.w;
    # must define one of the two:
    has $.ury;
    has $.h;

    submethod TWEAK() {
        # check mandatory attrs
        my $err = 0;
        my $msg = "FATAL: class Box undefined attrs:\n";
        if not $!id.defined {
            ++$err;
            $msg ~= "\$id\n";
        }
        if not $!llx.defined {
            ++$err;
            $msg ~= "\$llx\n";
        }
        if not $!lly.defined {
            ++$err;
            $msg ~= "\$lly\n";
        }
        if not $!urx.defined and not $!w.defined {
            ++$err;
            $msg ~= "\$urx and \$w\n";
        }
        if not $!ury.defined and not $!h.defined {
            ++$err;
            $msg ~= "\$ury and \$h\n";
        }

        die $msg if $err;
     
        # h vs ury
        # h has precedence over ury
        if $!h.defined {
            $!ury = $!lly + $!h;
        }
        elsif $!ury.defined {
            $!h   = $!ury - $!lly;
        }
        # w vs urx
        # w has precedence over urx
        if $!w.defined {
           $!urx = $!llx + $!w;
        }
        elsif $!urx.defined {
           $!w   = $!urx - $!llx;
        }
    }
} # class Box

class Field is export {
    # must define:
    has $.id  is rw;
    has $.llx is rw;

    # must define one of the two:
    has $.urx is rw;
    has $.w   is rw;

    submethod TWEAK() {
        # check mandatory attrs
        my $err = 0;
        my $msg = "FATAL: class Box undefined attrs:\n";
        if not $!id.defined {
            ++$err;
            $msg ~= "\$id\n";
        }
        if not $!llx.defined {
            ++$err;
            $msg ~= "\$llx\n";
        }
        if not $!urx.defined and not $!w.defined {
            ++$err;
            $msg ~= "\$urx and \$w\n";
        }

        die $msg if $err;
     
        # w vs urx
        # w has precedence over urx
        if $!w.defined {
           $!urx = $!llx + $!w;
        }
        elsif $!urx.defined {
           $!w   = $!urx - $!llx;
        }
    }
} # class Field

class Row is export {
    # must define:
    has $.id  is rw;
    has $.lly is rw;

    # must define one of the two:
    has $.ury is rw;
    has $.h   is rw;

    submethod TWEAK() {
        # check mandatory attrs
        my $err = 0;
        my $msg = "FATAL: class Box undefined attrs:\n";
        if not $!id.defined {
            ++$err;
            $msg ~= "\$id\n";
        }
        if not $!lly.defined {
            ++$err;
            $msg ~= "\$lly\n";
        }
        if not $!ury.defined and not $!h.defined {
            ++$err;
            $msg ~= "\$ury and \$h\n";
        }

        die $msg if $err;
     
        # h vs ury
        # h has precedence over ury
        if $!h.defined {
            $!ury = $!lly + $!h;
        }
        elsif $!ury.defined {
            $!h   = $!ury - $!lly;
        }
    }

    # left to right => 8 id keys a..h
    has Field %.fields is rw;
} # class Row

class Taxpayer is export {
    has $.names is rw;
    has $.ssan  is rw;
}

class Page is export {
    has Int $.id;
    has Row %.rows  is rw;
}

class Form is export {
    has $.id;
    has Page %.pages is rw; # page id should be the page number
}
