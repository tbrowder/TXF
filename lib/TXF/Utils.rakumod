unit module TXF::Utils;

sub Date2date(Date $d, :$debug --> Str) is export {
    # convert a Date object to mm/dd/yyyy string format
    return {sprintf "%02d/%02d/%04d", $d.month, $d.day, $d.year};
}
sub date2Date(Str $date, :$debug --> Date) is export {
    # date is expected in format: mm/dd/yyyy
    #   but it may be in other, similar formats
    # convert to and return a Date object
    # TODO simplify and make more robust
    my $dt;
    my ($year, $month, $day) = <9999 01 01>;
    if $date ~~ /(\d\d) '/' (\d\d) '/' (\d\d\d\d) / {
        $month = ~$0;
        $day   = ~$1;
        $year  = ~$2;
    }
    elsif $date ~~ /(\d\d\d\d) '-' (\d\d) '-' (\d\d) / {
        # the preferred ISO format
        my $year  = ~$0;
        my $month = ~$1;
        my $day   = ~$2;
    }
    elsif $date ~~ /(\d\d\d\d) '/' (\d\d) '/' (\d\d) / {
        $year  = ~$0;
        $month = ~$1;
        $day   = ~$2;
    }
    elsif $date ~~ /(\d\d\d\d) '.' (\d\d) '.' (\d\d) / {
        $year  = ~$0;
        $month = ~$1;
        $day   = ~$2;
    }
    else {
        note "Unexpected date string '$date', expected a variation of 'mm/dd/yyyy' format" if $debug;
    }
    return Date.new: "{sprintf "%04d-%02d-%02d", $year, $month, $day}";
}
