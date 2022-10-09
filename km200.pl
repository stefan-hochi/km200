#!/usr/bin/perl

use strict;
use warnings;

use lib '/root/lib';
use km200;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Cookies;
use JSON::MaybeXS qw(encode_json decode_json);
use Math::Round qw/nearest/;
use MIME::Base64 qw(encode_base64 decode_base64);

use Data::Dumper;

my $IPv4address = "GatewayAddress";
my $GatewayPassword = "GatewayPassword";
my $PrivatePassword = "PrivatePassword";

my ($hash, $def) = @_;
$def = "km200   km200   $IPv4address    $GatewayPassword        $PrivatePassword";
my $define = km200_Define(undef, $def);

$hash->{Secret}{CRYPTKEYPRIVATE} = $define;
$hash->{NAME} = "";
$hash->{URL} = $IPv4address;

my @Service;
my @BUDERUS_APIS;
my @BUDERUS_KNOWN_APIS = ("/system/sensors/temperatures", );

while (my ($key, $item) = each (@BUDERUS_KNOWN_APIS) ) {
        $hash->{temp}{service} = $key=$item;
        @Service = km200_GetSingleService($hash);
        traverse( {api => \@Service} );
}

@BUDERUS_APIS = (@BUDERUS_APIS , "/heatingCircuits/hc1/actualSupplyTemperature");
my @tmpArray;
while (my ($key, $item) = each (@BUDERUS_APIS) ) {
        $hash->{temp}{service} = $key=$item;
        @Service = km200_GetSingleService($hash);
        query( {api => \@Service} );
}

my $postparams = join ",", map { join "=", @$_ } @tmpArray;
if ($postparams) {
        $postparams = "km200,km200=km200" . " " . $postparams;
}

my $api = "InfluxDBAddress";
my $username = "PrivateUser";
my $password = "PrivatePassword";

my $authheader = "Basic " . encode_base64($username . ":" . $password);
my $request = HTTP::Request->new(POST => "http://" . $api . ":8086/write?db=mydb");
$request->header("Authorization" => $authheader);
$request->content($postparams);
my $ua = new LWP::UserAgent();
my $post = $ua->request($request);

#print Dumper($postparams);

sub traverse {
        my $param = shift;
        my $api = shift @{$param->{'api'}};
        if (defined $api->{references} && $api->{type} =~ /refEnum/)
        {
                #traverse( { api => \@{$api->{references}} } );
                while (my ($key, $item) = each (@{$api->{references}}) ) {
                        push(@BUDERUS_APIS,$key=$item->{id});
                }
        }
}

sub query {
        my $param = shift;
        my $api = shift @{$param->{'api'}};
        if (defined $api->{id} && $api->{type} =~ /floatValue/ && $api->{value} !~ /-3276.8/)
        {
                my $value = nearest('0.1',$api->{value});
                my $name = substr( $api->{id}, (rindex($api->{id}, "/")) );
                $name = $name =~ s/outdoor_t1/Außentemperatur/r;
                $name = $name =~ s/supply_t1/Vorlauftemperatur/r;
                $name = $name =~ s/hotWater_t2/Warmwassertemperatur/r;
                $name = $name =~ s/actualSupplyTemperature/VorlauftemperaturFuerHK/r;
                my @cell = ($name,$value);
                push(@tmpArray,\@cell);
        }
}

1;
