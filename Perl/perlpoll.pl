#!/usr/bin/perl -w
#Version 1.0.5
use LWP::UserAgent;
#use Net::SSLeay;
use strict;
no strict "subs";

use vars qw(%candidates_name %candidates_url %candidates_id %candidates_im);
$candidates_name{'John'}{'url'}             ='f04601649c4e1a4b35354ba1a1bb6fdd';
$candidates_name{'John'}{'id'}              ='7215679';
$candidates_name{'John'}{'im'}              ='1';
$candidates_url{'f04601649c4e1a4b35354ba1a1bb6fdd'}{'name'} ='John';
$candidates_url{'f04601649c4e1a4b35354ba1a1bb6fdd'}{'id'}   ='7215679';
$candidates_url{'f04601649c4e1a4b35354ba1a1bb6fdd'}{'im'}   ='1';
$candidates_id{'7215679'}{'name'}   ='John';
$candidates_id{'7215679'}{'url'}    ='f04601649c4e1a4b35354ba1a1bb6fdd';
$candidates_id{'7215679'}{'ref'}    ='32748419';
$candidates_id{'7215679'}{'file'}   ='http%3A//forourgloriousleader.weebly.com/poll-testing.html';
$candidates_id{'7215679'}{'im'} ='1';
$candidates_id{'7215679'}{'votes'}  ='50';
$candidates_im{'1'}{'name'} ='John';
$candidates_im{'1'}{'url'}  ='f04601649c4e1a4b35354ba1a1bb6fdd';
$candidates_im{'1'}{'id'}   ='7215679';


my %phone=();
$phone{'moty'}=7215679;

#SWITCH - if set to 1, the votes value for each candidate in %candidates_id are used to check if they reached their assigned amoutn of votes.
#If set to 0, it will be the votes of the prior candidates minus the value in auto_difference. In this case KJU always gets 49 votes.
#If set to 2, they will be loaded from a server - via proxy, of cause.
$phone{'use_individual_votes'}  =2;
$phone{'auto_difference'}   =3;

#User agent setting stuff.
#Notice we can go to ask the user some values - whom he want's to vote for, what proxy (if any) he wants to use ...
$phone{'ua'}=LWP::UserAgent->new();
$phone{'ua'}->agent('Mozilla/5.0 (Windows NT 6.1; rv:10.0) Gecko/20100101 Firefox/10.0');   #User agent
$phone{'ua'}->timeout(15);

print "Please insert proxy (Format: proto://IP:PORT, e.g 'http://1.2.3.4:5678') or press [ENTER] if you don't want to use any: ";
my $proxy=<STDIN>;
chomp($proxy);

if($proxy ne '')
{
    $phone{'ua'}->proxy(['http','https','ftp','upd']=>$proxy) or die "Malformed proxy address\n";
}

#Headers.
$phone{'ua'}->default_header('Accept'       =>'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
$phone{'ua'}->default_header('Accept-Language'  =>'en-us,en;q=0.5');
$phone{'ua'}->default_header('Referer'      =>'http://forourgloriousleader.weebly.com/poll-testing.html');
$phone{'ua'}->default_header('DNT'      =>1);
$phone{'ua'}->default_header('Connection'   =>'keep-alive');

#Some procs to make programmers life easier.

#Set or reset each ones post counter
sub void_candidates_counter()
{
    foreach(keys %candidates_id)
        {$phone{'counters'}{$_}=0;}
}

#Reloads the config from a server, if set.
sub reload_config
{
#   my @values=split(/,/,$phone{'ua'}->get("http://www.stullig.com/nkfiles/numbers.txt")->content);
#   my $i=0;
#   foreach my $im(sort {$a<=>$b} keys %candidates_im)
#   {
#       $candidates_id{$candidates_im{$im}{'id'}}{'votes'}=$values[$i++];
#   }
}

#Gets a decent formated time string for debug printouts.
sub get_local_time_string()
{
    my ($sec,$min,$hour,$day,$mon,$year)=localtime(time);
    $year+=1900;
    $mon++;
    foreach($sec,$min,$hour,$day,$mon)
        {s#^(\d)$#0$1#s}

    return "[$day.$mon.$year $hour:$min:$sec]";
}

#A stub for Javas time function - both work nearly the same.
sub get_mah_time(){return (time*1000);}

#Updates the target URLs in case the candidate you voted for has changed.
sub update_moty()
{
    $phone{'session_url'}   ="http://polldaddy.com/n/$candidates_id{$phone{'moty'}}{'url'}/$phone{'moty'}";

#   $phone{'poll_url'}  ="http://polls.polldaddy.com/vote-js.php?p=$phone{'moty'}&b=0&a=$candidates_id{$phone{'moty'}}{'ref'},&o=&va=0&cookie=0&n=7705338c8c|636&url=$candidates_id{$phone{'moty'}}{'file'}";
=for
    print &get_local_time_string()." SESSION: $phone{'session_url'}\n";
    print &get_local_time_string()." POLL: $phone{'poll_url'}\n";
=cut

}

#BTW we should set here the MOTY and update the URLs.
#The actual Man of the year's ID. Currently it's Kim - we gotta do some mapping here to ensure compartible vote requests.
&void_candidates_counter();
&update_moty();

#Fetches a new session from the pollday site.
sub get_new_session()
{
    $phone{'ua'}->default_header('Cookie'=>$phone{'raw_cookie'});
    my $result=$phone{'ua'}->get("$phone{'session_url'}?".(&get_mah_time()-1000*60*180))->content;
    #Getting the session from the response.
    if($result!~m#PDV_n$phone{'moty'}='([^']+)'#s)
    {
        print &get_local_time_string()." Something went wrong when fetching the session - cause I got no one: $result\n";
        return $result;
    }
=for
    print &get_local_time_string()." Success: $1\n";
=cut
    return $1;
}

#Do the actual vote - pass on a session and do it faggot
sub do_vote()

{
    my ($session)=($_[0]) or return;
    my $cookie=$phone{'raw_cookie'}." PD_poll_$phone{'moty'}_1=".(&get_mah_time()-1000*60*180);
=for
    print &get_local_time_string()." COOKIE: $cookie\n";
=cut
    $cookie='';
    $phone{'ua'}->default_header('Cookie'=>$cookie);
    my $request = "$phone{'poll_url'}$session";
    my $response=$phone{'ua'}->get($request);
    print &get_local_time_string()." REQUEST: $request\n";
    return $response;
}

#So THIS is the raw cookie the Time want's to get from us.
#The script works like that: first you get a generated session, then use it to do your vote. For the first you just need the cookie, for the second you additionally need to set
#a timestamp you get with get_mah_time.
$phone{'raw_cookie'}="pd-adsrc=google; __qca=P0-1338909366-1354132214914; km_ai=ug8cTGqQAJli5Y4JiLC11%2BI%2FC28%3D; kvcd=1354133975089; km_lv=1354133975; km_uq=; __utma=182033702.639645329.1354135226.1354135226.1354135226.1; __utmc=182033702; __utmz=182033702.1354135226.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none);";

#Statistic information
foreach(keys %candidates_id)
{
    $phone{'stats'}{$_}=
    {
        'total'         =>0,
        'total_successful'  =>0,
        'this_run'      =>0,
        'this_run_successful'   =>0
    };
}

#####################################################################################################################################
##XXX: ACUTAL START OF PROGRAM
##Let go into a loop, vote like the black devil and change identy if b& (if possible).
#####################################################################################################################################
$phone{'stats'}{'total'}=0;
$phone{'stats'}{'total_successful'}=0;
while(1)
{
    #Starting at the begin of the line?
    if(!defined($phone{'beginning_time'}))
    {
        $phone{'beginning_time'}=(time+10);
        &reload_config if($phone{'use_individual_votes'}==2);
    }

    if((!$phone{'use_individual_votes'} && $phone{'counters'}{$phone{'moty'}}>=(49-(($candidates_id{$phone{'moty'}}{'im'}-1)*$phone{'auto_difference'})))
    ||   $phone{'use_individual_votes'} && $phone{'counters'}{$phone{'moty'}}>=$candidates_id{$phone{'moty'}}{'votes'})
    {
        #First print, then reset the stats for this run.
        print "="x50;print "\n";
        print "Stats so far:\n";
        print "Total number of votes since the program was started: $phone{'stats'}{'total'}\n";
        print "Total number of votes which were successful: $phone{'stats'}{'total_successful'}\n";
        print "Total number of votes for the last candidate \"$candidates_id{$phone{'moty'}}{'name'}\": $phone{'stats'}{$phone{'moty'}}{'total'}\n";
        print "Total number of votes for the last candidate which were successful: $phone{'stats'}{$phone{'moty'}}{'total_successful'}\n";
        print "Total number of votes for the last candidate in the last run: $phone{'stats'}{$phone{'moty'}}{'this_run'}\n";
        print "Total number of votes for the last candidate in the last run which were successful: $phone{'stats'}{$phone{'moty'}}{'this_run_successful'}\n";
        print "="x50;print "\n";

        #Reset it.
        $phone{'stats'}{$phone{'moty'}}{'this_run'}=0;
        $phone{'stats'}{$phone{'moty'}}{'this_run_successful'}=0;

        #End of line? Start at the beginning.
        if(!exists($candidates_im{$candidates_id{$phone{'moty'}}{'im'}+1}))
        {
            &void_candidates_counter();
            $phone{'moty'}=$candidates_im{'1'}{'id'};
            print &get_local_time_string()." Sleeping for 10 minutes - please don't turn me off, I am working even if it does not look like\n";
            sleep((10*60)-(time-$phone{'beginning_time'})) if(((10*60)-(time-$phone{'beginning_time'}))>0);
            $phone{'beginning_time'}=undef;
        }
        else
        {
            $phone{'moty'}=$candidates_im{$candidates_id{$phone{'moty'}}{'im'}+1}{'id'};
        }
        print &get_local_time_string()." I will now root for candidate \"$candidates_id{$phone{'moty'}}{'name'}\" ...\n";
        &update_moty();
        next;
    }

    $phone{'stats'}{'total'}++;
    $phone{'stats'}{$phone{'moty'}}{'total'}++;
    $phone{'stats'}{$phone{'moty'}}{'this_run'}++;

    my $new_session=&get_new_session();
    next if(!$new_session);
    $phone{'poll_url'}      ="http://polls.polldaddy.com/vote-js.php?p=$phone{'moty'}&b=0&a=$candidates_id{$phone{'moty'}}{'ref'},&o=&va=0&cookie=0&n=$new_session&url=$candidates_id{$phone{'moty'}}{'file'}";
    my $response=&do_vote($new_session);

    #Successfully voted.
    if($response->content=~m#(Thank you for voting!)#s)
    {
        $phone{'stats'}{'total_successful'}++;
        $phone{'stats'}{$phone{'moty'}}{'total_successful'}++;
        $phone{'stats'}{$phone{'moty'}}{'this_run_successful'}++;

        print &get_local_time_string()." [VOTE: $phone{'stats'}{'total_successful'}; RUN: $phone{'stats'}{$phone{'moty'}}{'this_run_successful'}] $1\n";

        #Set the counter.
        $phone{'counters'}{$phone{'moty'}}++;
    }
    #Normal ban - let's change the candidate.
    elsif($response->content=~m#You will be unblocked after a cooling off period#s)
    {
        print &get_local_time_string()." Dammit, banned. Switching candidate ...\n";
        $phone{'counters'}{$phone{'moty'}}=50;
    }
    #Actually it should never happen that this string is returned - if it happens ... ehm, dunno.
    elsif($response->content=~m#(Thank you, we have already counted your vote\.)#s)
    {
        print &get_local_time_string()." '$1', looks like the cookie got old?\n";
    }
    #OK, you got me stumped ... Hölle verdammte.
    else
    {
        print &get_local_time_string()." Not what I expected: ".$response->content."\n";
    }
}

