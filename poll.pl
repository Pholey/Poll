use strict;

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->agent("Mac Safari");

my $time_now_in_epoc = time();
my $poll_id      = '7215679';
my $answer_id    = '32748420';
my $session_uri  = "http://polldaddy.com/n/f04601649c4e1a4b35354ba1a1bb6fdd/7215679?$time_now_in_epoc";
my $target_url   = 'http://forourgloriousleader.weebly.com/poll-testing.html';
my $polldaddy    = "http://polls.polldaddy.com/vote-js.php";

sub vote_id {
    my $s = sess();
    $s =~ m/'(.+?)'/;
    my $v = $1;
    # $v =~ s/\|/XXXPIPXXX/;
    return $v;
}

sub poll_url {
    my $vote_id = vote_id();
    # my %query_string;
    # $query_string{'p'} =       $poll_id;
    # $query_string{'b'} =       0;
    # $query_string{'a'} =       $answer_id,
    # $query_string{'o'} =       '';
    # $query_string{'va'} =      0;
    # $query_string{'cookie'} =  0;
    # $query_string{'n'} =       $vote_id;
    # $query_string{'url'} =     $target_url;

    my $url = $polldaddy . "?p=$poll_id&b=0&a=$answer_id&o=&va=0&cookie=0&n=$vote_id&url=$target_url$vote_id";
    # $uri->query_form(\%query_string);
    # my $url = $uri->as_string;
    # $url =~ s/XXXPIPXXX/\|/;
    # $url =~ s/%2F/\//g;
    print STDERR "poll_url: $url\n";
    return $url;
}

sub sess {
    return fetch_url($session_uri)
}

sub poll {
    return fetch_url(poll_url());
}

sub fetch_url {
    my $url = shift;
    my $request = HTTP::Request->new(GET => $url);
    my $response = $ua->request($request);
    return $response->content;
}

print poll(), "\n";



