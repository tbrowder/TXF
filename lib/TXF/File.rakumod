unit module TXF::File;

my @header-field-codes = <V A D>;
my @record-field-codes = <T N C L P D $>;

class File-actions {
}

grammar File-grammar {

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

