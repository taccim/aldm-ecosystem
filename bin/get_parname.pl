#!/usr/bin/env perl 
use Config;
#(my $par =  "/aldm-0.1-".$Config{archname}."-".$Config{api_versionstring}.".par" ) =~ s/-/%2D/g;
#if ( -f $ENV{PAR_CACHE}.$par ) {
#  $ENV{'ALDM_PAR'} = $ENV{PAR_CACHE}.$par;
#  }
#my $findpar = defined $ENV{'ALDM_PAR'} ? $ENV{'ALDM_PAR'}  : $ENV{'ALDM_REPO'};
#my $vStr = $Config{api_versionstring};
 

 my $osrel = (splice(@{[ split /\./,$Config{'osvers'}]},-2,1))[0];
 my $arch = (split /-/,$Config{'archname'})[0];
 my $perlv =  $Config{'version'};
 my $parfile = "aldm.par";
 
my $parname = sprintf("%s-%s-%s-%s",$osrel,$arch,$perlv,$parfile); 
print $parname,$/;
