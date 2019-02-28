#!/usr/bin/perl
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#                                           #
#  Copyright 01-Mar-2010 ITRS America Inc.  #
#                                           #
#                                           #
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# If the script has issues parsing data it will not print regular stdout
#  it will die with a message
#
# 24-Mar-2010 Version 7: Modified %cached and %cached to
#             %cached_read and %cahced_writes respectively
# Ensure good coding practices
use strict;
use warnings;
# Predefine some variables so that warning does not alert us
my $onstatCMD;
my $informixCommand;
my $switch;
my $databaseStatus;
#--------------------------------------------------------------------------------
# Allow the user to define the INFORMIXDIR environment variable in the toolkit
#  or in the netprobe environment, otherwise assume it is /opt/informix/bin/.
$onstatCMD = defined $ENV{'INFORMIXDIR'} ? "$ENV{'INFORMIXDIR'}/bin/onstat" : "/opt/informix/bin/onstat";
#--------------------------------------------------------------------------------
#chdir ($ENV{'INFORMIXDIR'}) if (defined $ENV{'INFORMIXDIR'});
#--------------------------------------------------------------------------------
# process command line arguments
$switch = shift;
if (defined $switch && $switch =~ /^-d|-p|-g|-h|-l|-k|-F$/) {
    if ($switch eq "-h") {
        # help menu
        &Usage;
    }
    else {
    if ($switch eq "-p") {
        $informixCommand = "$onstatCMD -p";
        #$informixCommand = "cat p";
        &onstat_p;
    }
    elsif ($switch eq "-d") {
        $informixCommand = "$onstatCMD -d";
        #$informixCommand = "cat d";
        &onstat_d;
    }
    elsif ($switch eq "-F") {
        $informixCommand = "$onstatCMD -F";
        #$informixCommand = "cat F";
        &onstat_F;
    }
    elsif ($switch eq "-k") {
        $informixCommand = "$onstatCMD -k";
        #$informixCommand = "cat k";
        &onstat_k;
    }
    elsif ($switch eq "-l") {
        $informixCommand = "$onstatCMD -l";
        #$informixCommand = "cat l";
        &onstat_l;
    }
    elsif ($switch eq "-g") {
        # exit if -g not called with correct arg
        if (!defined $ARGV[0] ||
        ($ARGV[0] ne 'glo' && $ARGV[0] ne 'seg' &&
         $ARGV[0] ne 'iov' && $ARGV[0] ne 'iof')) {
        &Usage;
        }
        else {
        if ($ARGV[0] eq 'glo') {
            $informixCommand = "$onstatCMD -g glo";
            #$informixCommand = "cat g_glo";
            if ($ARGV[1] eq 'vps') {
            &onstat_g_glo_vps;
            }
            elsif ($ARGV[1] eq 'ivp') {
            &onstat_g_glo_ivp;
            }
        }
        elsif ($ARGV[0] eq 'iof') {
            $informixCommand = "$onstatCMD -g iof";
            #$informixCommand = "cat g_iof";
            &onstat_g_iof;
        }
        elsif ($ARGV[0] eq 'iov') {
            $informixCommand = "$onstatCMD -g iov";
            #$informixCommand = "cat g_iov";
            &onstat_g_iov;
        }
        elsif ($ARGV[0] eq 'seg') {
            $informixCommand = "$onstatCMD -g seg";
            #$informixCommand = "cat g_seg";
            &onstat_g_seg;
        }
        }
    } # end if switch -g
    print "<!>onstat,$informixCommand\n";
    print "<!>status,$databaseStatus\n";
    }
}
else {
    # no valid arguments provided
    &Usage;
}
exit 0;
#________________________________________________________________________________
 
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Subroutines
#--------------------
# sub onstat_p
#  Subroutine for profile counts
#  this takes multiline output and converts it to a name value table assuming
#  that all coilumn headers have an associated value.
sub onstat_p {
    my @onstat_array = &execute_onstat;
    shift @onstat_array; # remove unecessary header
    $onstat_array[0] =~ s/(reads\s+.)cached/$1cached_reads/;
    $onstat_array[0] =~ s/(writs\s+.)cached/$1cached_writes/;
    my @output = &name_then_value(\@onstat_array);
    if ($#output == -1) {
    die "Error,Number of rows did not match data\n";
    }
    else
    {
    print "Name,Value\n";
    printf "<!>rows,%d\n",$#output+1;
    foreach (@output) {
        print "$_\n";
    }
    }
    return;
}
#____________________
#--------------------
# sub onstat_l
#  Subroutine for physical and logical logging
sub onstat_l {
    my @onstat_array = &execute_onstat;
    my @output = &splice(\@onstat_array,"^address *number");
    my $headline = pop (@output); # use trailing line as headline
    &simple_csv(\@output);
    foreach (@output) {
    print "$_\n";
    }
    foreach (split(',',$headline)) {
    my ($value,$name) = ($1,$2) if ($_ =~ /\s*(\d*)\s*(.*)/);
    print "<!>$name,$value\n";
    }
    return;
}
#____________________
#--------------------
# sub onstat_F
#  Subroutine for page to disk write flushers
sub onstat_F {
    my @onstat_array = &execute_onstat;
    my @output = &splice(\@onstat_array,"Fg Writes","address");
    pop @output; # remove unecessary trailing line
    $output[0] =~ s/ Write/_Write/g;
    print "Name,Value\n";
    foreach (&name_then_value(\@output)) {
    print "$_\n";
    }
    return;
}
#____________________
#--------------------
# sub onstat_k
#  Subroutine for Informix locks usages (summary)
sub onstat_k {
    my @onstat_array = &execute_onstat;
    my $data  = pop @onstat_array; # use trailing line as dataview
    print "Name,Value\n";
    foreach (split(',',$data)) {
    my ($value,$name) = ($1,$2) if ($_ =~ /\s*(\d*)\s*(.*)/);
    print "$name,$value\n";
    }
    return;
}
#____________________
#--------------------
# sub onstat_g_seg
#  Subroutine for Informix shared-memory segment statistics
sub onstat_g_seg {
    my @onstat_array = &execute_onstat;
    my @output = &splice(\@onstat_array,"^id.*key","^Total:");
    pop (@output); # remove unecessary trailing line
    &simple_csv(\@output);
    foreach (@output) {
    print "$_\n";
    }
    return;
}
#____________________
#--------------------
# sub switch_g_iov
#  Subroutine for global multithreading information
sub onstat_g_iov {
    my @onstat_array = &execute_onstat;
    shift @onstat_array; # remove unecessary header
    &fixed_length_csv(\@onstat_array,&cut2fmt_right($onstat_array[0]));
    foreach (@onstat_array) {
    s/(\S)\s+(\S)\,/$1_$2\,/; # I dont like key columns with spaces
    print "$_\n";
    }
    return;
}
#____________________
#--------------------
# sub switch_g_iof
#  Subroutine for Informix asynchronous I/O statistics by chunk or file
sub onstat_g_iof {
    my @onstat_array = &execute_onstat;
    shift @onstat_array; # remove unecessary header
     
    # the following array contains the header line
    # and the lines that line up with that header
    my @array = grep (/^gfd|^\d+\s+.*line_.*dbs/i,@onstat_array);
    $array[0] =~ s/ read/_read/g;   # get rid of unnecessary spaces in header
    $array[0] =~ s/ write/_write/g; # get rid of unnecessary spaces in header
    &fixed_length_csv(\@array,&cut2fmt_left($array[0]));
    foreach (@array) {
    print "$_\n";
    }
    return;
}
#____________________
#--------------------
# sub switch_g_glo_vps
#  Subroutine for global multithreading information virtual processor summary
sub onstat_g_glo_vps {
    my @onstat_array = &execute_onstat;
    my @output = &splice(\@onstat_array,"^ *class.*total","^ *total +");
    &simple_csv(\@output);
    pop(@output); # remove unecessary trailing line
    foreach (@output) {
    print "$_\n";
    }
    # process headlines
    @output = &splice(\@onstat_array,"^sessions","sched calls");
    pop(@output); # remove unecessary trailing line
    foreach (&name_then_value(\@output)) {
    print "<!>$_\n";
    }
    return;
}
#____________________
#--------------------
# sub switch_g_glo_ivp
#  Subroutine for global multithreading information global multithreading information
sub onstat_g_glo_ivp {
    my @onstat_array = &execute_onstat;
    my @output = &splice(\@onstat_array,"^ *vp *pid","^ *tot +");
    my @headline = (split(' ',pop(@output))); # use trailing line as headline
    &simple_csv(\@output);
    foreach (@output) {
    print "$_\n";
    }
    print "<!>total_usercpu,$headline[1]\n";         
    print "<!>total_syscpu,$headline[2]\n";          
    print "<!>total_totalcpu,$headline[3]\n";        
    return;
}
#____________________
#--------------------
# sub onstat_d
#  Subroutine for database utilisation
#  This function takes two tables, dbspaces and chunks, that have to be mapped.
#  A database may have more than one chunk associated with it, these need to be combined.
sub onstat_d {
    my @onstat_array = &execute_onstat;
    my $template;
    my @columns;
    my %col_Lookup;
    my %output;
    my @data;
    my @dbspaces = &splice(\@onstat_array,"^address.*number",".*active.*maximum");
    my $num_dbspaces = pop @dbspaces;  # remove unecessary trailing line
     
    my @chunks = &splice(\@onstat_array,"^address.*chunk",".*active.*maximum");
    my $num_chunks = pop @chunks; # remove unecessary trailing line
    # process dbspaces
    $template = &cut2fmt_left($dbspaces[0]); # get field size from headers
    @columns = split(' ',$dbspaces[0]); # store off column names for lookup
    # create a hash for column lookup so we know what column the data is in
    foreach my $i (0 .. $#columns) {
    $col_Lookup{$columns[$i]} = $i;
    }
    shift @dbspaces; # remove unecessary header
    # go thru each data line
    foreach (@dbspaces) {
    # take the data line and use it as an input for an array, per the header format
    @data = unpack("$template", $_);
    # store data name and number of chunks using database number as the key
    $output{$data[$col_Lookup{'number'}]}->{'name'}    = $data[$col_Lookup{'name'}];
    $output{$data[$col_Lookup{'number'}]}->{'nchunks'} = $data[$col_Lookup{'nchunks'}];
    }
    # process chunks
    $template = &cut2fmt_left($chunks[0]); # get field size from headers
    @columns = split(' ',$chunks[0]); # store off column names for lookup
    # create a hash for column lookup so we know what column the data is in
    foreach my $i (0 .. $#columns) {
        $col_Lookup{$columns[$i]} = $i;
    }
    shift @chunks; # remove unecessary header
    foreach (@chunks) {
    # take the data line and use it as an input for an array, per the header format
    @data = unpack("$template", $_);
    # the chunk index and the dbspace index are 2 values in one column
    my ($chunk,$number) = split(' ',$data[$col_Lookup{'chunk/dbs'}]);
    # store data using database number
    #  store individual chunk data under the chunk index
    $output{$number}->{'size'}->{$chunk} = $data[$col_Lookup{'size'}];
    $output{$number}->{'free'}->{$chunk} = $data[$col_Lookup{'free'}];
    }
    print "dbSpace,totalPages,pagesUsed,pagesFree,percentUtilisation,percentFreeSpace\n";
    # Print out all of the data, performing summing operations as necessary
    # foreach dbspace
    foreach my $key (sort keys %output) {
    # initialize vars
        my $size;
        my $free;
    # foreach chunk in dbspace
        foreach my $chunk (keys %{ $output{$key}->{'size'} }) {
        # sum up for total dbspace
            $size += $output{$key}->{'size'}->{$chunk};
            $free += $output{$key}->{'free'}->{$chunk};
         
        # print out individual chunk stat
        printf "%s,%d,%d,%d,%0.2f%%,%0.2f%%\n",
        "$output{$key}->{'name'}#chunk_$chunk",
        $output{$key}->{'size'}->{$chunk},
        $output{$key}->{'size'}->{$chunk}-$output{$key}->{'free'}->{$chunk},
        $output{$key}->{'free'}->{$chunk},
        100*(1 - $output{$key}->{'free'}->{$chunk}/$output{$key}->{'size'}->{$chunk}),
        100*$output{$key}->{'free'}->{$chunk}/$size;
        }
    # print out overall dbspace stat
        printf "%s,%d,%d,%d,%0.2f%%,%0.2f%%\n",
        $output{$key}->{'name'},$size,$size-$free,$free,100*(1 - $free/$size),100*$free/$size;
    }
     
    print "<!>dbspaces,$1\n" if ($num_dbspaces =~ /\s*(\d+)\s+active/i);
    print "<!>chunks,$1\n"   if ($num_chunks   =~ /\s*(\d+)\s+active/i);
    return;
}
#____________________
#@@@@@@@@@@@@@@@@@@@
#  Utility functions
#--------------------
# sub cut2fmt_right
#  Utility to use column headers to determine the length of valid data
#  Only needed if it is possible to have data values that are blank or
#  contain a space as part of the value
# the output is a format for the unpack function
sub cut2fmt_right {
    my $string = shift;
    my @indeces;
    my $template;
    while ($string =~ /^(\s*\S+)/) {
        my $length = length $1;            # find length of the matching substring
    push (@indeces,$length);           # store its length
    $string = substr($string,$length); # reduce the existing strength by this length
    last if ($string eq '');           # statement to avoid infinite loop
    }
    # Create template for all the different lengths found
    for my $i (0 .. $#indeces) {
        if ($i ==  $#indeces) {
            $template .= "A*";
        }
        else {
            $template .= "A$indeces[$i] ";
        }
    }
    return ($template);
}
#____________________
#--------------------
# sub cut2fmt_left
#  Utility to use column headers to determine the length of valid data
#  Only needed if it is possible to have data values that are blank or
#  contain a space as part of the value
# the output is a format for the unpack function
sub cut2fmt_left {
    my $string = shift;
    my @indeces;
    my $template;
    while ($string =~ /^(\s*\S+\s*)/) {
        my $length = length $1;            # find length of the matching substring
    push (@indeces,$length);           # store its length
    $string = substr($string,$length); # reduce the existing strength by this length
    last if ($string eq '');           # statement to avoid infinite loop
    }
    # Create template for all the different lengths found
    for my $i (0 .. $#indeces) {
        if ($i ==  $#indeces) {
            $template .= "A*";
        }
        else {
            $template .= "A$indeces[$i] ";
        }
    }
    return ($template);
}
#____________________
#--------------------
# sub simple_csv
#  Takes in an array reference with space seperated lines and turns it into a CSV
sub simple_csv {
    my $array_ref = shift;
    foreach (@$array_ref) {
    tr/\,/ /;  # translate any existing commas to spaces to avoid confusion
    s/\s+/ /g; # reduce multiple spaces to one
    s/^\s+//;  # get rid of leading spaces
    s/\s+$//;  # get rid of trailing spaces
    tr/ /\,/;  # tr spaces to commas
    }
    return;
}
#____________________
#--------------------
# sub fixed_length_csv
#  Takes in an array reference and a template as deteremined by cut2fmt and turns it into a CSV
sub fixed_length_csv {
    my $array_ref = shift;
    my $template  = shift;
    foreach (@$array_ref) {
    tr/\,/ /;                           # translate any existing commas to spaces to avoid confusion
    my @data = unpack("$template", $_); # Create an array of this split data
    $_ = join(',',@data);               # set the string to be comma seperated
        s/\s+/ /g;                          # reduce multiple spaces to one
    s/\, /\,/g;                         # remove spaces after commas
    s/^\s+//;                           # get rid of leading spaces
    s/\s+$//;                           # get rid of trailing spaces
    }
    return;
}
#____________________
#--------------------
# sub name_then_value
#  Takes header lines followed by data lines (alternating) and returns
#   an array with "name,value"
sub name_then_value {
    my $array_ref = shift;
    my (@name,@data,@output);
    for my $i (0 .. $#$array_ref) {
    if ($i % 2 == 0) {
        push (@name,split(' ',$$array_ref[$i]));
    }
    else {
            push (@data,split(' ',$$array_ref[$i]));
    }
    }
    if ($#name == $#data && $#name > -1) {
    for my $i (0 .. $#name) {
        $output[$i]= "$name[$i],$data[$i]";
    }
    }
    return (@output);
}
#____________________
#--------------------
# sub execute_onstat
#  Used to execute the onstat command and return an array that is already prefiltered
#  I always skip new lines and the IBM headers so set this up just once
sub execute_onstat {
    my @input;
    open (INPUT,"$informixCommand |") or die "Cannot execute command $informixCommand: $!\n";
    while (<INPUT>) {
        # skip blank lines or IBM header
    if ($_ =~ /^\s*$/) {
        next;
    }
    elsif ($_ =~ /^IBM Informix.*\s*--\s*(\S*)\s*--/) {
        $databaseStatus = $1;
        next;
    }
    elsif ($_ =~ /shared memory not initialized for INFORMIXSERVER/i) {
        die "informix offline" ;
    }
    else {
        chomp;
        push (@input,$_);
    }
    }
    return (@input);
}
#____________________
#--------------------
# sub splice
#  function to return an array that is a subset of the array ref supplied
#  input, array reference, start regex string, end regex string
#  perl does not handle exscape characters being passed to a subroutine so
#  regex has to be very simple
sub splice {
    my $array_ref   = shift;
    my $start_regex = shift;
    my $end_regex   = shift;
    my $start_ind = -1;
    my $end_ind   = -1;
    for my $i (0 .. $#$array_ref) {
    $start_ind = $i if ($$array_ref[$i] =~ /$start_regex/);
    $end_ind   = $i if (defined $end_regex && $$array_ref[$i] =~ /$end_regex/ && $start_ind > $end_ind);
    }
     
    $end_ind = $#$array_ref if ($end_ind == -1);
     
    if ($start_ind < $end_ind) {
    return @$array_ref[$start_ind..$end_ind];
    }
    else {
    return;
    }
}
#____________________
#--------------------
# sub Usage
#  Help display
sub Usage {
    print "informix.pl
 options:
     -d        \tdatabase utilisation
     -F        \tdisk write flushers
     -g glo ivp\tglobal multithreading information
     -g glo vps\tglobal multithreading information
     -g iof    \tasynchronous I/O statistics by chunk or file
     -g iov    \tasynchronous I/O statistics for each virtual processor
     -g seg    \tshared-memory segment stats
     -k        \tlocks usage
     -l        \tphysical and logical logging
     -p        \tprofile counts
     -h        \tthis help menu
";
    return;
}
#____________________