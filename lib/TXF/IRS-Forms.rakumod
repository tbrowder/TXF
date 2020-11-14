unit module TXF::IRS-Forms;

role Point is export { 
    has $.x is rw;
    has $.y is rw;
}

class Box does Point is export {
    has $.id is rw;
    has Point $.ll is rw;
    has Point $.ur is rw;
    method w { return $!ur.x - $!ll.x; }
    method h { return $!ur.y - $!ll.y; }
}

class Field is export {
    has $.id is rw;
    has $.llx is rw;
    has $.w is rw;
    has $.lrx is rw;
}

class Row is export {
    has $.id is rw;
    has $.lly is rw;
    has $.h is rw;
    has Field @.fields is rw;
}

class Taxpayer is export {
    has $.names;
    has $.ssan;
}

class Page is export {
    has $.id;
    has Row @.rows;
}

class Form is export {
    has $.id;
    has Page @.pages;
}

