#!/usr/bin/perl -w
use strict;
require 5.0;

##
#
# Author : Muthu Kumar Chandrasekaran
# Generate Feature Files with Stratified folds for cross-validation
# Modified in Mar, 2018
# e.g. cmd line, perl gen_features.pl -course eQJvsjn9EeWJaxK5AT4frw  -dbname coursera  -uni -allf
#
##

use DBI;
use FindBin;
use Getopt::Long;
use utf8::all;
use File::Remove 'remove';
use String::Util qw(trim);

my $path;	# Path to binary directory

BEGIN{
	if ($FindBin::Bin =~ /(.*)/)
	{
		$path  = $1;
	}
}

use lib "$path/../lib";
use FeatureExtraction;
use Model;
use Utility;

### USER customizable section
$0 =~ /([^\/]+)$/; my $progname = $1;
my $outputVersion = "1.0";
### END user customizable section

sub License{
	print STDERR "# Copyright 2014 \251 Muthu Kumar C\n";
}

sub Help{
	print STDERR "Usage: $progname -h\t[invokes help]\n";
  	print STDERR "       $progname -n -dbname -course [-allf -uni -cutoff -stem
										-tftype	-tprop -forumtype
										-courseref	-affir
										-nums -pdtb -pdtbexp -pdtbimp -agree  -q	]\n";
	print STDERR "Options:\n";
	print STDERR "\t-dbname database name \n";
	print STDERR "\t-cutoff \t Include only terms that have occured in atlest n documents. \n";
	print STDERR "\t-tftype[bool|pure|log] \n";
	print STDERR "\t-q \t Quiet Mode (don't echo license).\n";
}

my $help				= 0;
my $quite				= 0;
my $debug				= 0;
my $dbname				= undef;
my $mysqldbname			= undef;
my $courseid			= undef;

my $freqcutoff 			= undef;
my $stem				= 0;
my $tftype				= 'none';
my $term_length_cutoff	= 2;
my $idftype				= 'none';

my $allfeatures 		= 0;
my $numposts			= 0;
my $tprop				= 0;
my $numw				= 0;
my $numsentences 		= 0;

my $forumtype			= 0;
my $agree				= 0;

my $courseref			= 0;
my $nonterm_courseref 	= 0;
my $affirmations 		= 0;
my $viewed				= 0;

my $pdtb				= 0;
my $pdtb_imp			= 0;
my $pdtb_exp			= 0;

my $unigrams			= 0;

my $print_format		= 'none';

my $outfile;
my $tftab;

$help = 1 unless GetOptions(
				'allf'			=>	\$allfeatures,
				'dbname=s'		=>	\$dbname,
				'dumpdb=s'		=>	\$mysqldbname,
				'course=s'		=>	\$courseid,
				#FEATURES
				'uni'			=>	\$unigrams,
				'cutoff=i'		=>  \$freqcutoff,
				'lencut=i'		=>	\$term_length_cutoff,
				'tftype=s'		=>	\$tftype,
				'idftype=s'		=>	\$idftype,
				#NON-UNIGRAM FEATURES
				'forumtype'		=> 	\$forumtype,
				'affir'			=>	\$affirmations,
				'courseref'		=>	\$courseref,
				'nont_course'	=>	\$nonterm_courseref,
				'tprop'			=>	\$tprop,
				'nums'			=>	\$numsentences,
				'pdtb'			=>	\$pdtb,
				'pdtbexp'		=>	\$pdtb_imp,
				'pdtbimp'		=>	\$pdtb_exp,
				'view'			=>	\$viewed,
				'agree'			=>	\$agree,
				'stem'			=>	\$stem,
				#features end here
				'debug'			=>	\$debug,
				'h' 			=>	\$help,
				'q' 			=>	\$quite
			);

if ( $help ){
	Help();
	exit(0);
}

if (!$quite){
	License();
}

my $courses;
if(defined $courseid){
	push (@$courses, $courseid);
}
else{
	print "\n Exception! courseid not defined. Exiting.";
	Help();
	exit(0);
}

my $error_log_file	= "$path/../logs/$progname"."_$courseid".".err.log";
my $pdtbfilepath	= "$path/..";
my $log_file_name 	= "$progname"."_$courseid";
open (my $log ,">$path/../logs/$log_file_name.log")
				or die "cannot open file $path/../logs/$log_file_name.log for writing";

if($allfeatures){
	print $log "\n May include non-unigram features: tftype: $tftype idftype:$idftype\n";
}
elsif($unigrams){
	print $log "\n unigram features only: tftype: $tftype idftype:$idftype\n";
}

if(!defined $dbname){
	print $log "\n Exception: dbname not defined";
	print "\n Exception: dbname not defined"; exit(0);
}

my $db_path		= "$path/../data";
my $dbh 		= Model::getDBHandle($db_path,undef,undef,$dbname);


my @additive_sequence		= (0,1,3,7,15,31,63,127);
my @ablation_sequence		= (-31,47,55,59,61);
my @individual_features 	= (2,4,8,16,32);
my @combined				= (0,1,3,7,15,31,63,-31,47,55,59,61,2,4,8,16,32,64);
my @unigrams_only			= (0);
my @uni_plus_forumtype		= (0,1);
my @unigrams_plus			= (63);
my @the_rest				= (3,7,15,31);

my @edm 					= (31);
my @proposed				= (32, 64, 63, 127, 95);
my @edm_plus_pdtb_imp_exp	= (223, 159, 256);
my @edm_plus_pdtb_exp		= (95);
# my @iterations			= (0, 31, 32, 63, 64, 95, 127);
#my @iterations				= (223, 159, 95, 31, 64);
# my @iterations			= (256, 479);
my @iterations				= (63);

#sanity check
if(!$allfeatures && scalar @iterations > 1){
	print "\n\n Did you forget to switch 'allf' on?";
	print $log "\n\n Did you forget to switch 'allf' on?";
	Help();
	exit(0);
}

mkdir("$path/../experiments");
my $exp_path = "$path/../experiments";
$outfile = "../experiments/";

mkdir("$path/../tmp_file");
my $tmp_file = "$path/../tmp_file/tmp_samples_$courseid";

# CREATE MULTIPLE TEST AND TRAINING DATASETS FROM THE OVERALL
# LIST OF ALL COURSES

my $num_courses = 1;

my $threadsquery = 	"select docid, courseid, id,
						inst_replied from thread_new 
						where courseid = ?
							and forumid = ?";

my $threadssth = $dbh->prepare($threadsquery) 
			or die "prepare $threadsquery failed \n $DBI::errstr!\n";

my $corpus;

foreach my $course (@$courses){
	push (@$corpus, $course);
}

#sanity check
if(scalar @$corpus eq 0){
	print $log "# of courses in the corpus is zero. please pass a valid course name as an argument.";
	Help();
	exit(0);
}

my %docid_to_serialid		= ();
my %serialid_to_docid		= ();
my $serial_id				= 0;
my $corpus_type				= undef;

my %course_samples 			= ();
my %dataset 				= ();

#add all threads in the corpus
foreach my $courseid (@$corpus){
	my $forums = $dbh->selectall_arrayref("select id, forumname from forum
											where courseid =\'$courseid\'
											and forumname in
											('Homework','Lecture','Exam','Errata')"
										  )
							or die "forum query failed";
	foreach my $forumrow (@$forums){
		my $forumidnumber = $forumrow->[0];
		$threadssth->execute($courseid,$forumidnumber) or die "execute failed \n $!";
		my $threads = $threadssth->fetchall_arrayref() or die "thread query failed";

		foreach my $row ( @$threads ){
			my $courseid = $row->[1];
			my $threadid = $row->[2];
			$course_samples{$courseid}{$forumidnumber}{$threadid} = 1;
		}
	}
}

#sanity checks
if (keys %course_samples == 0 ){
	if($debug){
		print "\nException: Specified corpus not found!";
	}
	print $log "\nException: Specified corpus not found!";
	exit(0);
}

if (keys %course_samples != scalar @$corpus ){
	print $log "\nException: Only ". (scalar @$corpus)  ." out of ". (keys %course_samples) ." courses found in the corpus! Checking further...";
	foreach my $courseid (@$corpus){
		if (!exists $course_samples{$courseid} ){
			print $log "\nException: $courseid not found. Pls check courseid and the database";
		}
	}
	exit(0);
}

#add the threads to dataset hash
foreach my $courseid (@$courses){
	my $forums = $dbh->selectall_arrayref("select id, forumname from forum
											where courseid =\'$courseid\'
											and forumname in
											('Homework','Lecture','Exam','Errata')"
										  )
							or die "forum query failed";
	foreach my $forumrow (@$forums){
		my $forumidnumber	= $forumrow->[0];
		my $forumname 		= $forumrow->[1];
		$threadssth->execute($courseid,$forumidnumber) or die "execute failed \n $!";
		my $threads = $threadssth->fetchall_arrayref() or die "thread query failed";

		foreach my $row ( @$threads ){
			my $courseid = $row->[1];
			my $threadid = $row->[2];

			my $inst_replied	= $row->[3];
			my $docid 			= $row->[0];

			#Sanity checks
			if (!defined $docid ){
				print $log "DOCID is null for $courseid \t $threadid \t $forumidnumber \t $inst_replied \n";
				exit(0);
			}
			if (!defined $courseid ){
				die "courseid is null for $docid  \n";
			}
			if (!defined $threadid ){
				die "threadid is null for $docid \n";
			}
			if (!defined $forumname ){
				die "forumaname is null for $docid \n";
			}
			
			$dataset{$serial_id} = [$courseid,$threadid,$forumname,$forumidnumber];

			$docid_to_serialid{$serial_id}	= $docid;
			$serialid_to_docid{$docid} 		= $serial_id;
			$serial_id ++;
		}
		print $log "\n $courseid \t $forumidnumber\t" . (@$threads) ." threads";
	}
}

if (keys %dataset == 0 ){
	print "\nException: No + ve threads found!";
	exit(0);
}

my $experimentpath = "$path/../experiments/";

foreach my $iter (@iterations){
	my($d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$d10) = getBin($iter);
	print "\n Iteration $iter begins. Set $d0-$d1-$d2-$d3-$d4-$d5-$d6-$d7-$d8-$d9-$d10";
	if($allfeatures){
		$forumtype 			= $d0;
		$affirmations 		= $d1;
		$tprop	 			= $d2;
		$numsentences 		= $d3;
		$nonterm_courseref	= $d4;
		$courseref			= $d5;
		$agree				= $d6;
		$pdtb_exp			= $d7;
		$pdtb_imp			= $d8;
		$viewed				= $d9;
	}

	$outfile = "$exp_path/";
	if($unigrams){
		$outfile .= "uni+";
	}

	# output file
	$outfile  .=  $d0 	? "forum+"			: "";
	$outfile  .=  $d1 	? "affir+"  		: "";
	$outfile  .=  $d2 	? "tprop+"			: "";
	$outfile  .=  $d3 	? "nums+"			: "";
	$outfile  .=  $d4 	? "nont_course+"  	: "";
	$outfile  .=  $d5	? "course+" 		: "";
	$outfile  .=  $d6	? "agree+"			: "";
	$outfile  .=  $d7 	? "exppdtb+" 		: "";
	$outfile  .=  $d8 	? "imppdtb+" 		: "";
	$outfile  .=  $d9 	? "viewedins+" 		: "";
	
	print "\n Features switched on for this iteration $iter: $outfile";
	print $log "\n Features switched on for this iteration $iter: $outfile";

	$outfile 	.= "_". $courses->[0] . ".txt";

	#feature name file
	my $feature_file = "features";

	$feature_file .= $d0 	? "+forum"  	: "";
	$feature_file .= $d1 	? "+affir"		: "";
	$feature_file .= $d2 	? "+tprop"		: "";
	$feature_file .= $d3 	? "+nums"  		: "";
	$feature_file .= $d4 	? "+nont_course": "";
	$feature_file .= $d5	? "+course" 	: "";
	$feature_file .= $d6 	? "+agree"		: "";
	$feature_file .= $d7 	? "+exppdtb" 	: "";
	$feature_file .= $d8 	? "+imppdtb" 	: "";
	$feature_file .= $d9 	? "+viewedins" 	: "";
	

	$feature_file .= "_". $courses->[0] . ".txt";
	
	my @threads_to_predict = undef;
	
	foreach my $serial_id (keys %dataset){
		addtosample(\%dataset, $serial_id, '+1', \@threads_to_predict);
	}

	my %threadcats = ();
	$threadcats{1} = {
						'threads' 	=> \@threads_to_predict,
						'post'		=> 'post2',
						'comment'	=> 'comment2',
						'tftab'		=> 'termFreqC14inst'
					 };

	open (my $FH1, ">$tmp_file") or die "cannot open $tmp_file for writing \n $!";
	open (my $FEXTRACT, ">$error_log_file") or die "cannot open features file$!";

	FeatureExtraction::generateTrainingFile($FH1, $dbh, $mysqldbname, \%threadcats,
												$unigrams, $freqcutoff, $stem, $term_length_cutoff, $tftype, $idftype,
												$tprop, $numw, $numsentences,
												$courseref, $nonterm_courseref, $affirmations, $agree,
												$numposts, $forumtype,
												$exp_path, $feature_file,
												\%course_samples, $corpus, $corpus_type, $FEXTRACT, $log,
												$debug, $pdtb_exp, $pdtb_imp, $viewed,
												$pdtbfilepath, undef, $print_format
											);
	close $FH1;
	open (my $IN, "<$tmp_file") or die "cannot open $tmp_file file for reading \n $!";
	open (my $OUT, ">$outfile") or die "cannot open feature file: $outfile for writing $!";

	Utility::fixEOLspaces($IN,$OUT);

	close $OUT;
	close $IN;
}

if($debug){
	print "\n ##Done";
}

print $log "\n ##Done##";
close $log;
Utility::exit_script($progname,\@ARGV);

sub addtosample{
	my ($from_threads_dict, $serial_id, $label, $to_threads_arr) = @_;
	
	if (!defined $from_threads_dict ){
		die "Exception: addtosample: source threads  not defined.";
	}

	if (!defined $serial_id){
		die "Exception: addtosample: docid not defined.";
	}
	
	if (!defined $to_threads_arr){
		die "Exception: addtosample: target threads not defined.";
	}
	
	my $docid			= $docid_to_serialid{$serial_id};
	my $courseid		= $from_threads_dict->{$serial_id}->[0];
	my $threadid		= $from_threads_dict->{$serial_id}->[1];
	my $forumname		= $from_threads_dict->{$serial_id}->[2];
	my $forumidnumber	= $from_threads_dict->{$serial_id}->[3];

	if (!defined $threadid || !defined $courseid || !defined $docid || !defined $forumname){
		print $log "Exception: addtosample undef ser-$serial_id \t course-$courseid \t thread-$threadid \t doc-$docid \t forum-$forumname\n";
	}

	push (@$to_threads_arr, [$threadid,$docid,$courseid,$label,$forumname,$forumidnumber,$serial_id]);
}

sub getBin{
	my $given_number = shift;
	if(!defined $given_number){
		die "Exception: getBin Arg decimal_number not defined\n";
	}
	
	my $decimal_number = abs($given_number);
	
	my $d0 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	my $d1 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	my $d2 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	my $d3 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	my $d4 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	my $d5 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	my $d6 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	my $d7 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	my $d8 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	my $d9 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	my $d10 = $decimal_number%2;
	$decimal_number = $decimal_number/2;
	
	if ($given_number < 0 ){
		return (0, $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9);
	}
	else{
		return ($d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$d10);
	}
}