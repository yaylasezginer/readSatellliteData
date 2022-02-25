function [ice, lat, lon, time] = readNSIDC(filedir, latrange, lonrange, xorigin, yorigin)

%Read in ice data downloaded from the National Snow and Ice Data Center
%(NSIDC). Lat/Lon data from this is stereographically projected. Xgrid and
%ygrid is in units of meters from lon lat center point, respectively. Read the NSIDC data
%sheet to determine grid center point. 
% 
% Input:
% filedir - directory of single ice data file or folder containing ice data
% xorigin - NSIDC lon center point 
% yorigin - NSIDC lat center point
% latrange - latitude bounds of interest. format: [minlat maxlat]
% lonrange - longitude bounds of interest. format: [minlon maxlon]
% 
% OUTPUT: 
% ice - sea ice concentration index. A 3D matrix with size lat X lon X timeseries length
% lat - latitude coordinates converted into non-stereographic projection
% lon - longidtude coordinates coverted into non-stereographic projection
% date - date of data entry. 
% 
% Yayla Sezginer
% UBC Oceanography
% Updated: Nov 15, 2021
%===============================================================================================

% Single file or folder dir?
singlefile = contains(filedir,'.nc');

switch singlefile 
    case 1
    strpath = strsplit(filedir,'/');
    fn = strpath(end);
    filedir = strjoin(strpath(1:end-1),'/'); % put the path name back together excluding the filename. 
    case 0 
    folder = dir(filedir);
    fn = {folder.name};
    ncfile = contains(fn, '.nc');
    fn = fn(ncfile);
end

% make sure inputs are compatible
if latrange(1) >= latrange(2) || lonrange(1) >= lonrange(2)
    error('Coordinate ranges must be in the format [minlat/lon maxlat/lon]. First entry of coordinate range can''t be larger than second')
end

setup_nctoolbox
disp('Reading in data, this may take a while')
for i = 1:numel(fn)
    
    data = ncdataset([filedir '/' fn{i}]);
    xgrid = double(data.data('xgrid')); ygrid = double(data.data('ygrid'));
    %[x,y] = meshgrid(xgrid,ygrid);
    x = numel(xgrid); y = numel(ygrid);
    xgrid = repmat(xgrid,y,1); ygrid = repmat(ygrid,x,1);
    
    %Convert xgrid and ygrid (units: m) into lat x lon coordinates (units:
    %degrees)
    earthradius = 6378137.0;
    earth_eccentricity = 0.08181919;
    [lat_stereo,lon_stereo] = polarstereo_inv(xgrid,ygrid,earthradius,earth_eccentricity,yorigin,xorigin);
    
    %Keep only the selected lat/lon 
    
    lati = find(lat_stereo >= latrange(1) & lat_stereo <= latrange(2));
    loni = find(lon_stereo >= lonrange(1) & lon_stereo <= lonrange(2));
    ind = intersect(lati,loni);
 
    % parse the filename to get the time stamp 
    
    [ts,~] = strsplit(fn{i},{'_','A','.'},'CollapseDelimiters',true);
    timestr = ts{5};
    time(i) = datenum(str2double(timestr(1:4)),str2double(timestr(5:end)), 01);
    
    % read the data into the oceancolor matrix. 
    d = squeeze(double(data.data('cdr_seaice_conc_monthly')));
    d = reshape(d, x*y,1);
    ice(:,i) = d(ind);
    lat = lat_stereo(ind); lon = lon_stereo(ind);
end

