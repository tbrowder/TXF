unit module TXF::IRS-Forms;

=begin comment
role Point is export {
    has $.x is rw;
    has $.y is rw;
}

class Box does Point is export {
    has       $.id is rw;
    has Point $.ll is rw;
    has Point $.ur is rw;
    method w { return $!ur.x - $!ll.x; }
    method h { return $!ur.y - $!ll.y; }
}
=end comment

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
        if $!h.defined {
            $!ury = $!lly + $!h;
        }
        elsif $!ury.defined {
            $!h   = $!ury - $!lly;
        }
        # w vs urx
        if $!w.defined {
           $!urx = $!llx + $!w;
        }
        elsif $!urx.defined {
           $!w   = $!urx - $!llx;
        }
    }

    =begin comment
    # special override methods:
    # setters
    method set-urx($v) {
        $!urx = $v;
        $!w   = $!urx - $!llx;
    }
    method set-w($v) {
        $!w   = $v;
        $!urx = $!llx + $!w;
    }
    method set-ury($v) {
        $!ury = $v;
        $!h   = $!ury - $!lly;
    }
    method set-h($v) {
        $!h   = $v;
        $!ury = $!lly + $!h;
    }
    method finish {
        # h vs ury
        if $!h {
            $!ury = $!lly + $!h;
        }
        elsif $!ury {
            $!h   = $!ury - $!lly;
        }
        # w vs urx
        if $!w {
           $!urx = $!llx + $!w;
        }
        elsif $!urx {
           $!w   = $!urx - $!llx;
        }
    }
    =end comment
}

class Field is export {
    has $.id  is rw;
    # must define:
    has $.llx is rw;

    # must define one of the two:
    has $.urx is rw;
    has $.w   is rw;

    # special override methods:
    # setters
    method set-urx($v) {
        $!urx = $v;
        $!w   = $!urx - $!llx;
    }
    method set-w($v) {
        $!w   = $v;
        $!urx = $!llx + $!w;
    }
    method finish {
        # w vs urx
        if $!w {
           $!urx = $!llx + $!w;
        }
        elsif $!urx {
           $!w   = $!urx - $!llx;
        }
    }
}

class Row is export {
    has $.id  is rw;
    # must define:
    has $.lly is rw;

    # must define one of the two:
    has $.ury is rw;
    has $.h   is rw;

    # special override methods:
    # setters
    method set-ury($v) {
        $!ury = $v;
        $!h   = $!ury - $!lly;
    }
    method set-h($v) {
        $!h   = $v;
        $!ury = $!lly + $!h;
    }
    method finish {
        # h vs ury
        if $!h {
            $!ury = $!lly + $!h;
        }
        elsif $!ury {
            $!h   = $!ury - $!lly;
        }
    }

    # left to right => 8 id keys a..h
    has Field %.fields is rw;
}

class Taxpayer is export {
    has $.names is rw;
    has $.ssan  is rw;
}

class Page is export {
    has $.id        is rw;
    has Row %.rows  is rw;
    has Box %.boxes is rw;
}

class Form is export {
    has $.id         is rw;
    has Page @.pages is rw;
}
