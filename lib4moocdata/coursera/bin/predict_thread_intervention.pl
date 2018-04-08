#!/usr/bin/perl -w
use strict;
require 5.0;
use Algorithm::LibLinear;
use POSIX;


##
#
# Author : Muthu Kumar C
# Created in Spring, 2014
# Modified in Fall, 2015
# Modified in Spring, 2018
##

use FindBin;
use Getopt::Long;

my $path;	# Path to binary directory

BEGIN{
	if ($FindBin::Bin =~ /(.*)/)

	{
		$path  = $1;
	}
}

### USER customizable section
$0 =~ /([^\/]+)$/; my $progname = $1;
###

use lib "$path/../lib";
use Model;
use Utility;

my $datahome = "$path/experiments";

sub Help {
	print STDERR "Usage: $progname -h\t[invokes help]\n";
  print STDERR "       $progname -folds -in -indir[-cv|holdc -w -test -debug -q quiet]\n";
	print STDERR "Options:\n";

	print STDERR "\t-folds	\t # of folds for cross validation.\n";
	print STDERR "\t-indir	\t input directory\n";
	print STDERR "\t-in	  	\t input data file name in $datahome .\n";
	print STDERR "\t-q    	\t Quiet Mode (don't echo license).\n";
}

my $help = 0;
my $quite = 0;
my $debug = 0;
my $interactive = 0;
my $indir = undef;
my $in = undef;
my $stem = 0;
my $weighing = 'none';
my $dbname = undef;
my $incourse;
my $saved_model = undef;

$help = 1 unless GetOptions(
				'dbname=s'	=>	\$dbname,
				'course=s'	=>	\$incourse,
				'in=s'		=>	\$in,
				'indir=s'	=>	\$indir,   #redundant if  -course specified
				'stem'		=>	\$stem,
				'i'			=>	\$interactive,
				'w=s'		=>	\$weighing,
				'model=s'	=>	\$saved_model,
				'debug'		=>	\$debug,
				'h' 		=>	\$help,
				'q' 		=>	\$quite
			);

if ( ( $help ||  !defined $in)){
	Help();
	exit(0);
}

if (!defined $saved_model){
	print STDERR "Please input a trained model filename. It usually has a name that ends .model\n";
}

# Secure database connection as a global variable
my $dbh		= undef;
# my $dbh 	= Model::getDBHandle("$path/../data/",undef,undef,$dbname);

open (my $log, ">$path/../logs/$progname.log")
	or die "cannot open $path/../logs/$progname.log for writing";

my $experiments_path	 = "$path/../experiments";

if(defined $indir){
	$experiments_path	.= "/$indir";
}

my $results_path		 = "$experiments_path/results";

if(! -d $results_path){
	mkdir($results_path);
}

if(! -d "$experiments_path/models"){
	mkdir("$experiments_path/models");
}

my %output 			= ();
my %output_details	= ();
my %f1 				= ();
my %f2 				= ();
my %f4 				= ();
my %recall 			= ();
my %precision 		= ();
my %i_denC_test		= ();
my %svmweights 		= ();
my $weight_optimization_search_step = 0.1;
my $training_time 	= 0;
my $testing_time 	= 0;

my $basename	= (split(/_test_/,$in))[0];

#learnt model is written to this model file
my $model_file = "..models/$basename";

$saved_model = "../models/$saved_model";

my @courses;

if(defined $incourse){
	push(@courses, $incourse);
}

my $num_courses = scalar @courses;
if($num_courses == 0){
	print "Exception: zero courses found! Check data file.\n"; exit(0);
}

my $counter = 0;
my %docid_to_courseid = ();

open (my $result_file, ">$results_path/results_$basename"."_$incourse"."_$weighing.txt")
	or die "cannot open $results_path/results_$basename"."_$incourse"."_$weighing.txt for writing";
# print header
print $result_file "FOLD \t # of samples \t P \t R \t F_1 \t idenC_test \t FPR \t";
print $result_file "Train_+ve \t Train_-ve \t Test_+ve \t Test_-ve";

my $terms;
# $terms = Model::getalltermIDF($dbh,undef,0,\@courses,0);

my $weight		= 1;
my %data_to_shuffle_mapping = ();

my $lastname	= (split(/_test/,$in))[1];
$lastname =~ s/(\_)[0-9](.*\.?txt)/$1$2/;

my $test_data_file		= "$experiments_path/$in";

print "\n Test Data File: $test_data_file ";

my $test_data; my $ground_truth;

($test_data, $ground_truth) = readFeatureFile($test_data_file, $ground_truth);
print  "\n" . (keys %$ground_truth);

my $number_of_samples = keys %$test_data;

if($number_of_samples == 0){
	print "\n Exception: zero samples read! Check test data file.\n"; exit(0);
}

open (my $output_fold_fh, ">$results_path"."/results_dtl_".(split (/\./,$in))[0]."_$weighing.txt")
	or die "cannot open $experiments_path/results_dtl*.txt";

my ($sec,$min,$hour,@rest)	=  localtime(time);
my $start_timestamp 		= ($hour*60*60)+($min*60)+($sec);

## Naive SVM class weight computation from training data
my $init_weight = 1;

if ($weighing eq 'nve'){
		print $log "\n Setting naive class weights.";
		print $log "\n $init_weight";
		$weight =  $init_weight;
}
else{
	print $log "\n Invalid value for option -w (class weight) \n";
	print "\n Invalid value for option -w (class weight) \n";
	Help();
	exit(0);
}

#my $learner 	 = getClassifier($weight);
#my $training_set = Algorithm::LibLinear::DataSet->load(filename => "$experiments_path/DATA.train");
#my $classifier	 = $learner->train(data_set => $training_set);

my $classifier = Algorithm::LibLinear::Model->load(filename => $saved_model);

print $log "\n# Features: " . $classifier->num_features ;

#my $model_file_fold = $model_file . "_$incourse";
#$classifier->save(filename => $model_file_fold);
#$svmweights{$i} = getSVMweights($model_file_fold);

my ($sec1,$min1,$hour1,@rest) = localtime(time);
my $end_timestamp = ($hour1*60*60)+($min1*60)+($sec1);
my $duration = $end_timestamp - $start_timestamp;
$training_time += $duration;
printf $log "\n Training time: \t%02d second(s) \n", $duration;
printf "\n Training time :\t%02d second(s) \n", $duration;

($sec,$min,$hour,@rest) =   localtime(time);
$start_timestamp = ($hour*60*60)+($min*60)+($sec);

my @testset_docids;
#create test file
open TEST, ">$experiments_path/DATA.test";
foreach my $doc_id (keys %$test_data){
	push (@testset_docids, $doc_id);
	print TEST "$test_data->{$doc_id}\n";
}
close TEST;

my $test_set = Algorithm::LibLinear::DataSet->load(filename => "$experiments_path/DATA.test");
my $test_set_array_ref = $test_set->{'data_set'};

my %output = (); my $j = 0;
foreach my $test_instance (@$test_set_array_ref) {
	my $label	 = $test_instance->{'label'};
	my $features = $test_instance->{'feature'};

	# Determines which (+1 or -1) class should the test instance be assigned to
	# based on its feature vector.
	my $prediction = $classifier->predict(feature => $features);
	#my $predict_values = $classifier->predict_values(feature => $features);
	my $predict_values = $classifier->predict_probabilities(feature => $features);

	$output{$testset_docids[$j]}{$label} = $prediction;
	$output{$testset_docids[$j]}{$label} = $prediction;
	$output_details{$testset_docids[$j]} = +{	serialid 		=> $j,
												course			=> $incourse,
												label 			=> $label,
												prediction 		=> $prediction,
												predictvalue	=> $predict_values->[0],
												features		=> $features
											};
	$j++;
}
$j = 0;

($sec1,$min1,$hour1,@rest) =   localtime(time);
$end_timestamp = ($hour1*60*60)+($min1*60)+($sec1);
$duration = $end_timestamp - $start_timestamp;
# printf "Test time for fold $i\t%02d second(s)", $duration;
$testing_time += $duration;

my $matrix	= getContigencyMatrix(\%output);
printContigencyMatrix($matrix, $result_file);
#savedetailedouput(\%output, $test_data, $output_fold_fh, 1);
savedetailedouput(\%output_details, $test_data, $output_fold_fh, 1);

$precision{0}	= sprintf ("%.3f", getPrecision($matrix) * 100 );
$recall{0}		= sprintf ("%.3f", getRecall($matrix) * 100 );
$f1{0}			= sprintf ("%.3f", computeF_m($matrix,1) * 100 );
$f2{0}			= sprintf ("%.3f", computeF_m($matrix,2) * 100 );
$f4{0}			= sprintf ("%.3f", computeF_m($matrix,4) * 100 );

my $num_pos_samples = ($matrix->{'tp'} + $matrix->{'fn'});
my $num_neg_samples = ($matrix->{'fp'} + $matrix->{'tn'});
my $fpr;

if($matrix->{'fp'} + $matrix->{'tn'} eq 0 ){
	$fpr 	= 0;
}
else{
	$fpr	= sprintf ("%.3f", ($matrix->{'fp'} / ($matrix->{'fp'} + $matrix->{'tn'}) * 100 ));
}

my $p_at_100r = 0;
if($num_pos_samples > 0 ){
	$p_at_100r = ($num_pos_samples / ($num_pos_samples + $num_neg_samples));
}
my $f1_at_100r	= (2*$p_at_100r*1) / ($p_at_100r+1);
my $f4_at_100r	= ((1+16)*($p_at_100r*1)) / ((16*$p_at_100r)+1);

$p_at_100r	= sprintf ("%.3f", $p_at_100r * 100 );
$f1_at_100r	= sprintf ("%.3f", $f1_at_100r * 100 );
$f4_at_100r	= sprintf ("%.3f", $f4_at_100r * 100 );

if ( $num_neg_samples ne 0){
	$i_denC_test{0}  = sprintf ("%.3f", $num_pos_samples / $num_neg_samples );
}
else{
	$i_denC_test{0}  = 0;
}

print $result_file "\n $incourse \t $number_of_samples \t $precision{0}\t $recall{0} \t $f1{0}";

print $result_file "\t $i_denC_test{0}\t $fpr\t";

print $result_file "\t $num_pos_samples ";
print $result_file "\t $num_neg_samples ";
print $result_file "\n at_100 \t \t $p_at_100r \t 100 \t $f1_at_100r\t \n";
close $result_file;

printf "\nTotal time elapsed: \t%02d second(s)", $testing_time;

Utility::exit_script($progname,\@ARGV);
# MAIN ENDS HERE #

sub getSign{
	print  "\n Enter sign + or - or 0: ";
	my $sign = <STDIN>;
	$sign = untaint($sign);
	if ($sign eq '+'){return +1;}
	if ($sign eq '-'){return -1;}
	return 0;
}

sub getFold{
	#my($num_folds) = @_;
	my $num_folds = 14;
	print  "\n Enter a fold between 1 and $num_folds: ";
	my $fold = <STDIN>;
	$fold = untaint($fold);
	return ($fold-1);
}

sub getClassifier{
	my ($weight,$solver_type) = @_;

	if(!defined $solver_type){
		$solver_type = 'L1R_LR';
	}
	## Instantiate Liblinear SVM with the weight
	# Constructs a model either
	# a) L2-regularized L2 loss support vector classification.
	# b) L1-regularized Logit model
	my $learner = Algorithm::LibLinear->new(
												epsilon 	=> 0.01,
												#solver 	=> 'L2R_L2LOSS_SVC_DUAL',
												solver	 	=> $solver_type,
												weights 	=> [
																+{ label => +1, weight => $weight,	},
																+{ label => -1, weight => 1,		},
															   ]
											);
}

sub test{
	my ($filename, $path, $model) = @_;
	my $test_set	= Algorithm::LibLinear::DataSet->load(filename => "$path/$filename");
	my $test_set_array_ref = $test_set->{'data_set'};

	my %output = ();
	my $test_inst_id = 0;
	foreach my $test_instance (@$test_set_array_ref) {
		my $label = $test_instance->{'label'};
		my $features = $test_instance->{'feature'};

		my $prediction = $model->predict(feature => $features);
		my $predict_values = $model->predict_values(feature => $features);
		$output{$test_inst_id}{$label} = $prediction;
		$test_inst_id ++;
	}

	my $matrix = getContigencyMatrix(\%output);

	my $f1	= sprintf ("%.3f", computeF_m($matrix,1) * 100 );
	return $f1;
}

sub writeDataFile{
	my ($filename, $path, $data) = @_;

	#create data file
	open CVTRAIN, ">$path/$filename";
	foreach my $j (keys %$data){
		print CVTRAIN "$data->{$j}\n";
	}
	close CVTRAIN;
}

sub getCourseid{
	my $courses = shift;
	foreach my $course (@$courses){
		print "$course \t";
	}
	print "\n Enter a course to display: ";
	my $input_course = <STDIN>;
	$input_course =~ s/\s*(.*)\s*/$1/;
	return $input_course;
}

sub microAverageF_m{
	my($foldwise_matrix, $beta) = @_;
	my $tp; my $fp;
	my $precision = microAveragedPrecision($foldwise_matrix);
	my $recall = microAveragedRecall($foldwise_matrix);
	my $numera =  (1+($beta*$beta)) * ($precision*$recall);
	my $denom = ($beta*$beta*$precision)+$recall;
	my $f_m = ($denom == 0) ? 0: ($numera/$denom);

	return $f_m;
}

sub computeF_m{
	my($matrix, $beta) = @_;
	my $precision = getPrecision($matrix);
	my $recall = getRecall($matrix);
	my $numera =  (1+($beta*$beta)) * ($precision*$recall);
	my $denom = ($beta*$beta*$precision)+$recall;
	my $f_m = ($denom == 0) ? 0: ($numera/$denom);
	return $f_m;
}

sub getContigencyMatrix{
	my $output = shift ;
	my %matrix = ();

	$matrix{'tp'} = 0;
	$matrix{'fp'} = 0;
	$matrix{'tn'} = 0;
	$matrix{'fn'} = 0;
	$matrix{'+'}  = 0;
	$matrix{'-'}  = 0;

	for my $id (keys %$output){
		for my $label (keys %{$output->{$id}}){
			if( $label eq 1 ){
				if ( $output->{$id}{$label} eq 1){
					$matrix{'tp'} ++;
				}
				else{
					$matrix{'fn'} ++;
				}
			}
			else{
				if ( $output->{$id}{$label} eq 1){
					$matrix{'fp'} ++;
				}
				else{
					$matrix{'tn'} ++;
				}
			}
		}
	}
	return \%matrix;
}

sub printContigencyMatrix{
	my($matrix, $FH) = @_;
	print "\n------------------------------\n";
	print "\tActual +\tActual -\n";
	print "------------------------------\n";
	print "Predicted +|\t$matrix->{'tp'}|\t$matrix->{'fp'}|\n";
	print "Predicted -|\t$matrix->{'fn'}|\t$matrix->{'tn'}|\n";
	print "------------------------------\n";

	if (defined $FH){
		# print $FH "\n------------------------------\n";
		# print $FH "\tActual +\tActual -\n";
		# print $FH "------------------------------\n";
		print $FH "\t$matrix->{'tp'} \t$matrix->{'fp'}";
		print $FH "\t$matrix->{'fn'} \t $matrix->{'tn'}";
		# print $FH "------------------------------\n";
	}
}

sub getPrecision{
	my($matrix) = @_;
	my $denom = ($matrix->{'tp'} + $matrix->{'fp'} );
	my $p = ($denom == 0) ? 0: ($matrix->{'tp'})/$denom;
	return $p;
}

sub microAveragedPrecision{
	my($foldwise_matrix) = @_;
	my $tp; my $fp;
	foreach my $fold (keys %$foldwise_matrix){
		$tp += $foldwise_matrix->{$fold}{'tp'};
		$fp += $foldwise_matrix->{$fold}{'fp'};
	}
	my $denom = ($tp + $fp );
	my $p = ($denom == 0) ? 0: ($tp)/$denom;
	return $p;
}

sub getRecall{
	my($matrix) = @_;
	my $denom = ($matrix->{'tp'}+$matrix->{'fn'} );
	my $r = ($denom == 0) ? 0: ($matrix->{'tp'})/$denom;
}

sub microAveragedRecall{
	my($foldwise_matrix) = @_;
	my $tp; my $fn;
	foreach my $fold (keys %$foldwise_matrix){
		$tp += $foldwise_matrix->{$fold}{'tp'};
		$fn += $foldwise_matrix->{$fold}{'fn'};
	}
	my $denom = ($tp + $fn );
	my $r = ($denom == 0) ? 0: ($tp)/$denom;
	return $r;
}

sub average{
	my($hash) = @_;
	my $average = 0;
	foreach (keys %$hash){
		$average += $hash->{$_} ;
		#print "\n Hash value: $_ \t $hash->{$_}";
	}
	$average = $average/ (keys %$hash);
	$average = (sprintf "%.3f",$average);
	#print "\n Avg: $average";
	return $average;
}

sub weightedAverage{
	my($hash,$size) = @_;
	my $average = 0;
	my $number_of_samples = 0;
	my $weight_sum = 0;
	foreach my $fold (keys %$size){
		$number_of_samples += $size->{$fold};
	}

	foreach (keys %$hash){
		my $weight = $size->{$_}/$number_of_samples;
		$weight_sum += $weight;
		$average += ($weight * $hash->{$_}) ;
		#print "\n Hash value: $_ \t $hash->{$_} \t size:$size->{$_} \t $number_of_samples \t $weight";
	}
	#print "\n Avg: $average";
	print "\n Weight sum: $weight_sum";
	$average = (sprintf "%.3f",$average);
	return $average;
}

## Analysis functions

sub getSwitch{
	print  "\n 1. Contingency Matrix";
	print  "\n 2. Error analysis: Analyse docids by error type";
	print  "\n 3. Print Error thread metadata to file";
	print  "\n 4. Error analysis: print feature vector";
	print  "\n 5. Print Ranked features";
	print  "\n 6. Quit";
	print  "\n Enter an analysis option: ";
	my $switch = <STDIN>;
	$switch = untaint($switch);
	return $switch;
}

sub printFeatureVector{
	my($dbh,$docid) = @_;

	my($threadid,$courseid) = Model::getthread($dbh,$docid);
	print "\n--------------------------------------------------------";
	print "\n THREAD: $threadid \t DOCID: $docid \t COURSE : $courseid\n";

	my $termfreq;
	$termfreq = Model::getterms($dbh,$threadid,$courseid,$docid);

	my %termindex =();

	foreach my $termid (keys %$termfreq){
		#my $termidf = Model::gettermIDF($dbh,$termid,$stem);
		#my $tfidf = $termfreq->{$termid}{'sumtf'} * $termidf;
		#push (my @termrow, ($termid, $_->[1], $_->[2], $termidf, $tfidf));
		#push @termarray, \@termrow;
		$termindex{$termid} = +{id		=>	$termid,
								term	=>	$termfreq->{$termid}{'term'},
								tf		=>	$termfreq->{$termid}{'sumtf'}
								#idf		=>	$termidf,
								#tfidf	=>	$tfidf
							}
	}
	displayFeatureVector($docid,\%termindex);
}

sub makehashcopy{
	my ($hash2d) = @_;
	my %copy = ();

	foreach my $k1 (keys %$hash2d){
		foreach my $k2 (keys %{$hash2d->{$k1}} ){
			$copy{$k1}{$k2} = $hash2d->{$k1}{$k2};
		}
	}
	return \%copy;
}

sub untaint{
	my $input = shift;
	chomp $input;
	$input =~ s/\s*(.*)\s*/$1/g;
	return $input;
}

sub savedetailedouput{
	my ($foldoutput, $data, $fh, $level) = @_;
		print $fh  "Id \t Prediction Score";
	foreach my $id ( keys %{$foldoutput} ){
		if(!defined $level){
			print $fh "\n $data->{$id}\t";
		}else{
			print $fh "\n $id \t";
			print $fh "$foldoutput->{$id}{'predictvalue'}";
		}
		#foreach my $label ( keys %{$foldoutput->{$id}} ){
		#	print $fh "$label\t$foldoutput->{$id}{$label}";
		#}
	}
}


sub save_detailed_ouput2db{
	my ($foldoutput, $data) = @_;
		print  "Id \t Prediction Score";
	foreach my $id ( keys %{$foldoutput} ){
		#$id
		#$foldoutput->{$id}{'predictvalue'}
		#insert each of these values to the thread table
	}
}

sub deduplicate_array{
	my $arrayref = shift;
	my @array = @{$arrayref};
	my %hash   = map { $_, 1 } @array;
	my @unique = keys %hash;
	return \@unique;
}

sub readFeatureFile{
	my ($in, $ground_truth)	=	@_;

	print "\n Reading $in";
	my %data = ();
	open DATA, "<$in" or die "Cannot open $in";

	while (<DATA>){
		chomp($_);
		$_ =~ s/\s*$//g;
		my @line = (split /\t/, $_);
		$line[0] =~ s/\s*$//g;
		my $docid = $line[0];

		my $dataline = join ("\t", @line[1..$#line]);
		$dataline =~ s/^\s*(.*)\s*$/$1/;

		# extract label and record as ground truth
		my $label	= $line[1];
		$label		=~ s/\s+//g;
		$ground_truth->{$docid} = $label;

		if( !exists $data{$docid} ){
			$data{$docid} = $dataline;
		}else{
			# print "\n docid: $docid ";		#  . (split /\t/, $dataline)[0];
			#print "\n Existing: $data{$docid}";	# . (split /\t/, $data{$docid})[0] ."\n";
		}
	}
	close DATA;
	return (\%data, $ground_truth);
}

=pod
# Executes cross validation.
#my $accuracy = $learner->cross_validation(data_set => $data_set, num_folds => 5);
#print "ACC: $accuracy\n";
=cut
