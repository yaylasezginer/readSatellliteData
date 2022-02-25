
function [oceancolor, lat, lon] = readNASAL3(filedir,var,latrange,lonrange)
% Read NASA .nc files downloaded from the nasa level 3 browser. 
%
% INPUT
% filedir - either the name of a single file or the directory of for a
% folder holding several files. 
% var - variable of interest in string format (i.e. 'chlor_a', 'ipar' etc)
%
% OUTPUT
% oceancolor - variable of interest (i.e. [chl] or PAR, etc).
% Lat, Lon - arrays of lat lon coordinates
% time - array with time stamps 
%
% Yayla Sezginer
% Nov, 2021
% UBC Oceanography
%==========================================================================


singlefile = strcmp(filedir,'.nc');

switch singlefile 
    case 1
    fn = [];
    case 0 
    folder = dir(filedir);
    fn = {folder.name};
    ncfile = contains(fn, '.nc');
    fn = fn(ncfile);
end

%make sure inputs are compatible
if latrange(1) >= latrange(2) || lonrange(1) >= lonrange(2)
    error('Coordinate ranges must be in the format [minlat/lon maxlat/lon]. First entry of coordinate range can''t be larger than second')
end

%Open each data file in the folder

setup_nctoolbox
disp('Reading in data, this may take a while')
for i = 1:numel(fn)
    data = ncdataset([filedir '/' fn{i}]);
    Lat = double(data.data('lat')); Lon = double(data.data('lon'));
    
    %Keep only the selected lat/lon 
    
    latkeep = Lat >= latrange(1) & Lat <= latrange(2);
    lonkeep = Lon >= lonrange(1) & Lon <= lonrange(2);
    lat = Lat(latkeep); lon = Lon(lonkeep);
    
    % parse the filename to get the time stamp 
    
     %[ts,~] = strsplit(fn{i},{'A','_','.'},'CollapseDelimiters',true); %for chl products
     %timestr = ts{2};
     %time(i) = datenum(str2double(timestr(1:4)),0, str2double(timestr(5:7)));
    
    %read the data into the oceancolor matrix. 
    d = squeeze(double(data.data(var)));
    oceancolor(:,:,i) = d(latkeep,lonkeep);
end

end
