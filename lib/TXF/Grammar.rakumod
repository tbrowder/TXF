unit grammar TXF::Grammar;

my @header-field-codes = <V A D>;
my @record-field-codes = <T N C L P D $>;
#grammar TXF-grammar {

    #token TOP { 
    #    <.separation>
    #    <header> \s* <record>+ 
    #}

    token TOP {
        .*
    }

    token header-field-code { @header-field-codes }
    token record-field-code { @record-field-codes }    
    token end-of-record     { '^' }
    token header-field      { ^^ <header-field-code> $<value>=\N* $$ }
    token record-field      { ^^ <record-field-code> $<value>=\N* $$ }

    token separation { \s* }

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
#}
