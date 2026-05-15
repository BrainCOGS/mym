function compile_mexmaca64()
% Build script for MyM (64-bit ARM Mac OS)
%
% Notes:
%
%   1. we're relying on the system zlib.

mym_base = fileparts(fileparts(mfilename('fullpath')));
mym_src = fullfile(mym_base, 'src');
build_out = fullfile(mym_base, 'build', mexext());
distrib_out = fullfile(mym_base, 'distribution', mexext());

% Set up input and output directories
% Use Homebrew mariadb-connector-c for MariaDB server compatibility
mysql_base = '/opt/homebrew/opt/mariadb-connector-c';
mysql_include = fullfile(mysql_base, 'include', 'mariadb');
mysql_lib = fullfile(mysql_base, 'lib');

mkdir(build_out);
mkdir(distrib_out);
oldp = cd(build_out);
pwd_reset = onCleanup(@() cd(oldp));

mex_opts = fullfile(mym_base, 'mex_compilation', 'clang++_maca64_mym.xml');

mex( ...
    '-v', ...
    '-largeArrayDims', ...
    '-f', mex_opts, ...
    sprintf('-I"%s"', mysql_include), ...
    sprintf('-L"%s"', mysql_lib), ...
    '-lmariadb', ...
    '-lz', ...
    fullfile(mym_src, 'mym.cpp'));


% Find libmariadb path linked into mex
[~,old_link] = system(['otool -L ' ...
    fullfile(build_out, ['mym.' mexext()]) ...
    ' | grep libmariadb | tail -1 |awk ''{print $1}''']);

% Change libmariadb reference to mym mex directory
system(['install_name_tool -change "' strip(old_link) '" "' ...
    fullfile('@loader_path','lib', 'libmariadb.3.dylib') '" "' ...
    fullfile(build_out, ['mym.' mexext()]) '"']);

% Pack mex with all dependencies into distribution directory
copyfile(['mym.' mexext()], distrib_out, 'f');
copyfile(fullfile(mym_src, 'mym.m'), distrib_out, 'f');
mkdir(fullfile(distrib_out, 'lib'));
copyfile(fullfile(mysql_lib, 'libmariadb.3.dylib'), fullfile(distrib_out,'lib'), 'f');
