unit module TXF::IRS-Forms;

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

class Field is export {
    has $.id  is rw;
    has $.llx is rw;
    has $.w   is rw;
    has $.lrx is rw;
}

class Row is export {
    has $.id  is rw;
    has $.lly is rw;
    has $.ury is rw;
    has $.h   is rw;
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
