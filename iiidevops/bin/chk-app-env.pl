#!/usr/bin/perl

$branch = defined($ARGV[0])?lc($ARGV[0]):'master';
$env_file = 'iiidevops/app.env';
$branch_env_file = "$env_file.$branch";
print("Check branch env_file : [$branch_env_file]..\n");
if (-e $branch_env_file) {
	$tmpl = `cat $branch_env_file`;
	open(FH, '>', $env_file) or die $!;
	print FH $tmpl;
	close(FH);
	
	$cmd_msg = `cat $env_file`;
	print("\n-----\n$cmd_msg\n-----\n");
}
