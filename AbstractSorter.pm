=head1 NAME

AbstractSorter.pm - an abstract class used for sorting arrays

=head1 SYNOPSIS

     ##################                          ##################
     ################## EXAMPLES OF SIMPLE USAGE ##################
     ##################                          ##################
     
     use SubSorter;
     my $sorter = SubLayerSorter->new();
     
     my @sorted = $sorter->sort(@array);
     #note: "ByNumeric" must be defined by the SubSorter
     my @sorted_different = $sorter->sortBy("ByNumeric",@array);


=head2 METHODS

=over 12

=item C<new>

I<< new() >>

Creates a new Sorter object.

=item C<sort>

I<sort(@array)>

Returns a sorted array, in the default assigned ordering.

=item C<sortBy>

I<sortBy("ByMethod",@array)>

Takes two parameters a B<string> "ByMethod" and an array to be sorted. Returns a sorted array which is ordered defined by "ByMethod"

=item C<debugOn>

I<debugOn()>

Turns on scripting debug statements.

=item C<debugOff>

I<debugOff()>

Turns off scripting debug statements.

=back

=head2 METHODS THAT NEED TO BE IMPLEMENTED

=over 12

=item C<_init>

Needs to pass on the parameters to $self

Does not return anything.

=item C<_compare>

Takes two parameters.

If parameter 1 is greater than parameter 2 it returns a positive number.

If the two parameters are equal it returns 0.

Otherwise it returns a negative number.

=back

=head1 DEPENDENCIES

Carp

Scalar::Util

=head1 AUTHOR

Matthew Bundy (mattb@protechmn.com)

=cut

package AbstractSorter;

#------------------------------ Start the module here ------------------------#

use Carp;
use warnings;
use strict;
use lib "$ENV{GENESIS_DIR}/sys/scripts/matt/perlmod/genesis/structure";

#note AbstractLayerSorter cannot be instantiated directly; it must be subclassed.
#no need to override this function in child class
sub new {
     #constructor method
     #require parameters
     #None
     my $class = shift;
     #don't allow instantiation of an abstract class; it must be inherited
     die __PACKAGE__ ." is an abstract class" if $class eq __PACKAGE__;
     my $self = bless {}, $class;
     $self->_init(@_);
     $self->_checkInterfaceBaseClass();

     #Any local variables
     $self->{DEBUG} = 0;

     return $self;
}

sub sort {
     #sort the given array by the child class defined _compare function
     my $self = shift;
     my @array = @_;
     return $self->sortBy("",@array);;
}

sub sortBy {
     use Scalar::Util 'blessed';

     my $self = shift;
     my $fun = shift;
     my @layers = @_;
#check that the compare function is defined in the child class
     my $class = blessed($self);
     my $compareFunction = "_compare" . $fun;
     $self->can($compareFunction) or die $class . " {$compareFunction} not defined";
#do the sorting
     my $sorted = \@layers;
     my $len = @{$sorted};
     $self->_mergeSort($compareFunction,$sorted);
     return @{$sorted};
}
#TODO implement this in child class
#takes a list of parameters
#set up the instance variables for the object
#minimum implementation must define $self->{JOB_MOD} and $self->{_type}
#here is an example
#
#     # @override
#     sub _init {
#          my $self = shift;
#          my %params = @_;
#          foreach my $param (keys %params) {
#               $self->{$param} = $params{$param};
#          }
#          $self->{_type} = "drill";
#          return;
#     }
sub _init {
     my $self = shift;
     use Scalar::Util 'blessed';
     my $class = blessed($self);
     die $class . " Failed to initialize. Initialization is not yet defined";
}

#TODO implement this in child class
#takes two parameters
#returns a number
#if a < b it should return some number less than 0
#if a = b it should return 0
#if a > b it should return some number greater than 0

sub _compare {
     my $self = shift;
     my ($a,$b) = @_;
     use Scalar::Util 'blessed';
     my $class = blessed($self);
     die $class . " compare Failed. compare function is not yet defined";
}

#for additional compare functions use the following pragma

#sub _compareBySomeMethod {...}

#when the sortBy function is called the first parameter must match "BySomeMethod" exactly ie
#sub _compareByFoo {...}
#sortBy("ByFoo", @array)
#or
#sub _compareBroccoli {...}
#sortBy("Broccoli",@array)



#check that the child class has these methods/variables
sub _checkInterfaceBaseClass {
     my $self = shift;
     use Scalar::Util 'blessed';
     my $class = blessed($self);
     my @requiredMethods = qw /_init _compare/; #these methods need to be implemented in the child class
     my @requiredVariables = qw //; #these variables must be initialized in the child class
     foreach my $method (@requiredMethods) {
          $self->can($method) or die $class . " {$method} not defined";
     }
     foreach my $variable (@requiredVariables) {
          if (!defined $self->{$variable}) {
               die $class . " {$variable} not defined";
          }
     }
}

sub _checkType {
     #checks that all they layers match the defined type
     #_type is defined in the child class
     #if the type doesn't matter then set it to 'any'
     my $self = shift;
     my @layers = @_;
     if ($self->{_type} eq 'any') {
          return
     }
     foreach my $layer (@layers) {
          my $layerType = $self->{JOB_MOD}{"LAYER" . $layer}{TYPE};
          if ($self->{_type} ne $layerType) {
               carp ("WARNING TYPE MISMATCH ($self->{_type}, $layerType)\n");
          }
     }
}

     #the main function used for sorting parameterize by the child class compare function
sub _mergeSort {
     my $self = shift;
     my $compareFunc = shift;
     my ($array) = @_;
     if (@{$array} <= 1) {return}
     
     my $mid = int (@{$array}/2);
     my @left = @{$array}[0..$mid-1];
     my @right = @{$array}[$mid..@{$array}-1];
     
     $self->_mergeSort($compareFunc,\@left);
     $self->_mergeSort($compareFunc,\@right);
     
     $self->_merge($compareFunc,\@left,\@right, $array);
}

sub _merge {
     no strict "refs"; #need this so $self->$compareFunc doesn't fail
     #compareFunc comes from the child class
     my $self = shift;
     my $compareFunc = shift;
     my ($a_ref, $b_ref, $array) = @_;
     my ($i, $j, $r) = (0,0,0);

     while ($i < @{$a_ref} && $j < @{$b_ref}){
          if ($self->$compareFunc($a_ref->[$i],$b_ref->[$j]) < 0){
               $array->[$r++] = $a_ref->[$i++];
          }else{
               $array->[$r++] = $b_ref->[$j++];
          }
     }
     $array->[$r++] = $a_ref->[$i++] while ($i < @{$a_ref});
     $array->[$r++] = $b_ref->[$j++] while ($j < @{$b_ref});

}

sub debugOn {
     #changes local variable DEBUG to 1 to enable debug conditionals
     my $self = shift;
     $self->{DEBUG} = 1;
}

sub debugOff {
     #changs local variable DEBUG to 0 to dissable debug conditionals
     my $self = shift;
     $self->{DEBUG} = 0;
}

# --- Modules need to return 1 to indicate to the compilier it is successfully loaded
1;
