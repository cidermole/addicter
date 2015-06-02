#!/usr/bin/perl
# Knihovna funkcí pro práci se systémem souborů a pro bezpečné volání externích procesů v Linuxu.
# © 2010, 2012, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package dzsys;
use utf8;
use open ':utf8';
use cas;



#------------------------------------------------------------------------------
# Zařídí pro otevřený výstupní soubor autoflush mezi každými dvěma perlovými
# příkazy. Vhodné např. k tomu, aby se v terminálovém okně míchaly STDOUT a
# STDERR chronologicky.
#------------------------------------------------------------------------------
sub autoflush
{
    my $soubor = shift; # např. *STDOUT
    my $old_fh = select($soubor);
    $| = 1;
    select($old_fh);
}



#------------------------------------------------------------------------------
# Vrátí seznam podsložek dané složky s výjimkou '.' a '..'.
#------------------------------------------------------------------------------
sub get_subfolders
{
    my $cesta = shift;
    opendir(DIR, $cesta) or die("Cannot read folder $cesta: $!\n");
    my @objects = readdir(DIR);
    closedir(DIR);
    return grep {!m/^\.\.?$/ && -d "$cesta/$_"} (@objects);
}



#------------------------------------------------------------------------------
# Vrátí seznam souborů (ne podsložek) v dané složce.
#------------------------------------------------------------------------------
sub get_files
{
    my $cesta = shift;
    opendir(DIR, $cesta) or die("Cannot read folder $cesta: $!\n");
    my @objects = readdir(DIR);
    closedir(DIR);
    return grep {-f "$cesta/$_"} (@objects);
}



#------------------------------------------------------------------------------
# Rekurzivně vrátí seznam všech souborů a složek v podstromu dané složky.
#------------------------------------------------------------------------------
sub get_descendants
{
    my $cesta = shift;
    my @subfolders = get_subfolders($cesta);
    my @files = get_files($cesta);
    my @descendants;
    foreach my $sf (@subfolders)
    {
        push(@descendants, $sf);
        my $sfcesta = "$cesta/$sf";
        my @sfdescendants = map {"$sf/$_"} get_descendants($sfcesta);
        push(@descendants, @sfdescendants);
    }
    push(@descendants, @files);
    return @descendants;
}



#------------------------------------------------------------------------------
# Otevře soubor na disku ke čtení. Jestliže je soubor zagzipovaný, funkce ho
# při čtení rozgzipuje. Vrátí handle souboru. Hodí výjimku, jestliže soubor
# nejde otevřít (chybná cesta, nedostatečná práva atd.)
#------------------------------------------------------------------------------
sub gopen
{
    my $cesta = shift;
    if($cesta =~ m/\.gz$/)
    {
        $cesta = "gunzip -c $cesta |";
    }
    # Jestliže open() dostane místo handlu neinicializovanou lokální skalární
    # proměnnou, vyrobí a vloží do ní anonymní lokální handle, který sám zanikne,
    # až skončí aktuální blok a zaniknou všechny odkazy na něj. (Pokud tedy
    # volající nechce, aby mu handle zanikl, musí ho vložit do globální proměnné.)
    my $handle;
    open($handle, $cesta) or die("Cannot read file $cesta: $!\n");
    return $handle;
}



#------------------------------------------------------------------------------
# Otevře soubor na disku ke psaní. Jestliže jméno souboru končí na .gz, funkce
# ho při psaní zagzipuje. Vrátí handle souboru. Hodí výjimku, jestliže soubor
# nejde otevřít (chybná cesta, nedostatečná práva atd.)
#------------------------------------------------------------------------------
sub gwopen
{
    my $cesta = shift;
    $cesta =~ s/^\s*>\s*//;
    if($cesta =~ m/\.gz$/)
    {
        $cesta = "| gzip -c > $cesta";
    }
    else
    {
        $cesta = ">$cesta";
    }
    # Jestliže open() dostane místo handlu neinicializovanou lokální skalární
    # proměnnou, vyrobí a vloží do ní anonymní lokální handle, který sám zanikne,
    # až skončí aktuální blok a zaniknou všechny odkazy na něj. (Pokud tedy
    # volající nechce, aby mu handle zanikl, musí ho vložit do globální proměnné.)
    my $handle;
    open($handle, $cesta) or die("Cannot read file $cesta: $!\n");
    return $handle;
}



#------------------------------------------------------------------------------
# Rozbalí zagzipovaný soubor do dočasného umístění a vrátí cestu k němu. Hodí
# se v případě, že dotyčný soubor nečteme přímo naším skriptem, ale voláme
# cizí program, který neočekává zagzipovaný vstup. Je na volajícím, aby posléze
# rozbalený soubor uklidil. Proto také neobalujeme rozbalený soubor žádnou
# složkou, aby odstraňování bylo jednodušší.
#------------------------------------------------------------------------------
sub gunziptmp
{
    my $pathgz = shift;
    my $nameungz = $pathgz;
    $nameungz =~ s-^.*/--;
    $nameungz =~ s/\.gz$//;
    $nameungz = 'gunzipped' if($nameungz =~ m/^\s*$/);
    my $location = get_tmp_location();
    my $unique_name = get_unique_filename($location, $nameungz);
    my $pathungz = "$location/$unique_name";
    saferun("gunzip -c $pathgz > $pathungz") or die;
    return $pathungz;
}



#------------------------------------------------------------------------------
# Calls an external program. Uses system(). In addition, echoes the command
# line to the standard error output, and returns true/false according to
# whether the call was successful and the external program returned 0 (success)
# or non-zero (error).
#
# Typically called as follows:
#     saferun($command) or die;
#------------------------------------------------------------------------------
sub saferun
{
    my $command = join(' ', @_);
    my $ted = cas::ted()->{datumcas};
    print STDERR ("[$ted] Executing: $command\n");
    system($command);
    # The external program does not exist, is not executable or the execution failed for other reasons.
    if($?==-1)
    {
        die("ERROR: Failed to execute: $command\n  $!\n");
    }
    # We were able to start the external program but its execution failed.
    elsif($? & 127)
    {
        printf STDERR ("ERROR: Execution of: $command\n  died with signal %d, %s coredump\n",
            ($? & 127), ($? & 128) ? 'with' : 'without');
        die;
    }
    # The external program ended "successfully" (this still does not guarantee
    # that the external program returned zero!)
    else
    {
        my $exitcode = $? >> 8;
        print STDERR ("Exit code: $exitcode\n") if($exitcode);
        # Return false if the program returned a non-zero value.
        # It is up to the caller how they will handle the return value.
        # (The easiest is to always write:
        # saferun($command) or die;
        # )
        return ! $exitcode;
    }
}



#------------------------------------------------------------------------------
# A variant of saferun() for cases where we normally want to call `command` and
# read its STDOUT.
#------------------------------------------------------------------------------
sub safeticks
{
    my $command = join(' ', @_);
    my $tmp = get_tmp_folder('safeticks');
    my $tmpfile = "$tmp/stdout.txt";
    saferun("( $command ) > $tmpfile") or die;
    my $result = `cat $tmpfile`;
    unlink($tmpfile) or die("Cannot remove $tmpfile: $!\n");
    rmdir($tmp) or die("Cannot remove $tmp: $!\n");
    return $result;
}



#------------------------------------------------------------------------------
# A variant of safeticks() without the trailing (CR)LF.
#------------------------------------------------------------------------------
sub chompticks
{
    my $result = safeticks(@_);
    $result =~ s/\r?\n$//;
    return $result;
}



#------------------------------------------------------------------------------
# Another variant that skips the safety procedures and any STDERR messages
# ("q" for "quiet") but removes the trailing (CR)LF.
#------------------------------------------------------------------------------
sub qcticks
{
    my $command = join(' ', @_);
    my $result = `$command`;
    $result =~ s/\r?\n$//s;
    return $result;
}



#------------------------------------------------------------------------------
# Returns the location of the temporary folder. According to ÚFAL policy, tries
# /mnt/h/tmp first. If it does not exist, tries /tmp, then the current path.
#------------------------------------------------------------------------------
sub get_tmp_location
{
    my $tmp;
    if(-d '/mnt/h/tmp')
    {
        $tmp = '/mnt/h/tmp';
    }
    elsif(-d '/tmp')
    {
        $tmp = '/tmp';
    }
    else
    {
        $tmp = '.';
    }
    return $tmp;
}



#------------------------------------------------------------------------------
# Creates a unique temporary folder. According to ÚFAL policy, tries /mnt/h/tmp
# first. If it does not exist, tries /tmp, then the current path.
#------------------------------------------------------------------------------
sub get_tmp_folder
{
    my $name = shift;
    my $tmp = get_tmp_location();
    # Create a unique subfolder in that location.
    return get_tmp_folder_in($tmp, $name);
}



#------------------------------------------------------------------------------
# Creates a unique temporary folder at a given location. This function is
# called by get_tmp_folder(). It can also be called directly by the user if
# they need to create a folder at a specific location (for instance, working
# folders of parallelized cluster jobs must be accessible from the whole
# network, thus they can be neither in /tmp nor in /mnt/h/tmp).
#------------------------------------------------------------------------------
sub get_tmp_folder_in
{
    my $location = shift;
    my $name = shift;
    if($name eq '')
    {
        $name = 'workdir';
    }
    my $path = get_unique_filename($location, $name);
    mkdir($path) or die("Cannot create $path: $!\n");
    return $path;
}



#------------------------------------------------------------------------------
# Finds a unique name for file or folder. Starts by appending the current
# process ID to the name proposed by the caller. If it is taken, increments the
# number (originally PID) until an available name is found.
#------------------------------------------------------------------------------
sub get_unique_filename
{
    my $location = shift; # where the file will reside
    my $name = shift; # name proposed by the caller (without the process ID)
    # Append the current process id to minimize the risk of duplicite names.
    my $i = $$;
    my $path;
    # Check that the name is unique.
    while(1)
    {
        $path = "$location/$name.$i";
        if(-e $path)
        {
            $i++;
        }
        else
        {
            last;
        }
    }
    return "$name.$i";
}



#==============================================================================
# Functions to get absolute paths.
#==============================================================================



#------------------------------------------------------------------------------
# Figures out the current absolute path. If we want to know the caller's path
# we must call this before we change the current folder.
#------------------------------------------------------------------------------
sub get_current_path
{
    my $mydir = is_windows() ? `cd` : `pwd`;
    $mydir =~ s/\r?\n$//;
    return $mydir;
}



#------------------------------------------------------------------------------
# Figures out the absolute path to the script.
#------------------------------------------------------------------------------
sub get_script_path
{
    my $scriptdir = $0;
    # Strip script name, leave path to its folder.
    if($scriptdir !~ m-/-)
    {
        $scriptdir = ".";
    }
    else
    {
        # Remove the rightmost slash and everything after it.
        $scriptdir =~ s-/[^/]*$--;
    }
    my $current_path = get_current_path();
    chdir("$scriptdir") or die("Cannot change to $scriptdir folder: $!\n");
    $scriptdir = get_current_path();
    chdir($current_path) or die("Cannot change to $current_path folder: $!\n");
    return $scriptdir;
}



#------------------------------------------------------------------------------
# Concatenates two paths. If the right path is absolute, the left path is
# ignored. Otherwise, the right path is relative to the left path (which could
# be relative as well).
#------------------------------------------------------------------------------
sub join_paths
{
    my $left = shift;
    my $right = shift;
    if($right =~ m-^/-)
    {
        return $right;
    }
    else
    {
        $left =~ s-/$--;
        return $left."/".$right;
    }
}



#------------------------------------------------------------------------------
# Makes a relative path absolute. Joins the absolute current path.
#------------------------------------------------------------------------------
sub absolutize_path
{
    my $path = shift;
    return join_paths(get_current_path(), $path);
}



#==============================================================================
# Functions to deal with Linux-Windows differences.
#==============================================================================



#------------------------------------------------------------------------------
# Pokusí se zjistit, zda běžíme pod Microsoft Windows. V tom případě nelze
# volat některé externí programy, např. pwd.
#------------------------------------------------------------------------------
sub is_windows
{
    return exists($ENV{windir});
}



#------------------------------------------------------------------------------
# Nahradí všechna lomítka v řetězci zpětnými lomítky. Hodí se, když máme cestu
# slepenou z kusů různého původu a chceme ji použít v příkazu pro Windows.
#------------------------------------------------------------------------------
sub slash_windows
{
    return map {s:/:\\:g; $_} @_;
}



#------------------------------------------------------------------------------
# Nahradí všechna zpětná lomítka v řetězci normálními lomítky. Hodí se, když
# máme cestu slepenou z kusů různého původu a chceme ji použít v příkazu pro
# Linux.
#------------------------------------------------------------------------------
sub slash_linux
{
    return map {s:\\:/:g; $_} @_;
}



1;
