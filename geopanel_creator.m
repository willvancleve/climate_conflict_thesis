% data must start with january
% from acled dataset, set edate, fatalities, elat, elong
% figure out monthcount starting point
% currently replaces temp value of observations already in cell, need to
% avg


%Array indeces:
% 1 - grid id
% 2 - qstring
% 3 - qtr
% 4 - fat
% 5 - events
% 6 - total temp
% 7 - count test
% 8 - precip
% 9 - yr
% 10 - gdp
% 11 - crop
% 12 - livestock
% 13 - temp lagged 1 q
% 14 - precip lagged 1 q
% 15 - lat
% 16 - long
% 17 - temp lagged 1 yr
% 18 - precip lagged 1 yr
% 19 - nightlight density
% 20 - ls2

%% INPUTS 

% import conflict, climate, gdp datasets

    % set variable names from acled
    edate_in = EVENT_DATE;
    fatalities = FATALITIES;
    elat = LATITUDE;
    elong = LONGITUDE;

    % set total number of grids and quarters
    % grids = 4;
    % quarters = 4;
    
    % set to number of variables for each observation
    arraylength = 20;

    % input gridded climate data
    % set upper and lower index for lat, long, and yr in 720x360 dataset
    lat_lo = 0;
    lat_hi = 15;
    long_lo = 0;
    long_hi = 15;
    input_lo = 1901;
    yr_lo = 2009;
    yr_hi = 2015;
    
    % subset to narrow geo region
    sublat_lo = 8;
    sublat_hi = 15;
    sublong_lo = 8;
    sublong_hi = 15;
    
    % control data
    feyr = Year;
    gdp = GDP;
    crop = ag;
    lstock = ls1;
    growth = GDPGrowth;
    nighlights = nl;
    lstock2 = ls2;
    
    % add cells to this array if fatality occurs in cell
    celltracker = zeros;
    cti = 1;
    
    index = 1;
    for i = 1:length(edate_in);
        datestr = strsplit(char(edate_in(i)),'/');
        if str2double(datestr(3)) >= yr_lo
            if str2double(datestr(3)) <= yr_hi
                edate(index) = edate_in(i);
                index = index + 1;
            end
        end
    end

    % .nc filenames 
    temp_filename = 'tmp1901_2015.dat.nc';
    precip_filename = 'pre1901_2015.dat.nc';
    
    



% create master matrix of cell arrays - set arraylength to number of
% variables at each observation

grids = (lat_hi-lat_lo) * (long_hi-long_lo);
quarters = (yr_hi-yr_lo+1) * 4;
master = cell(grids, quarters);
for i = 1:grids
    for j = 1:quarters
        newarray = cell(arraylength,1);
        master{i,j} = newarray;
    end
end

%% Fatality/Event Data


% read in fatalities from acled dataset and store in master matrix
l = length(edate);
ii = 1;
while ii < l
    q = toquarter((edate(ii)));
    iY = toquarterindex(q,yr_lo);
    g = togrid(elat(ii),elong(ii));
    iX = togridindex(g,long_hi-long_lo);
    
    % cells w/fatalities in array
    if ismember(iX,celltracker) == 0
        celltracker(cti) = iX;
        cti = cti+1;
    end
    
    a = master{iX,iY};
    % a{1} = num2cell(iX);
    % a{2} = q;
    % a{9} = num2cell(q2yr(q));
    % {3} = num2cell(q2q(q));
    a{8} = 0;
    a{7} = 0;
    a{14} = 0;
    
    if isempty(a{4})
        fat = 0;
    else fat = cell2mat(a{4});
    end
    fat = fat + fatalities(ii);
    a{4} = num2cell(fat);
    
    if isempty(a{5})
        events = 0;
    else events = cell2mat(a{5});
    end
    events = events + 1;
    a{5} = num2cell(events);
    master{iX,iY} = a;
    ii = ii + 1;
end

celltracker = sort(celltracker);

%% Read Climate Data



% read variables from .nc data files
lat = ncread(temp_filename,'lat');
lon = ncread(temp_filename,'lon');
tmp = ncread(temp_filename,'tmp');
precip = ncread(precip_filename,'pre');   % check variable name

%% Store Climate Data in master


i = 1;
while lat(i) < lat_lo
    i = i+1;
end
ilat_lo = i;
while lat(i) < lat_hi
    i = i+1;
end
ilat_hi = i-1;
i = 1;
while lon(i) < long_lo
    i = i+1;
end
ilong_lo = i;
while lon(i) < long_hi
    i = i+1;
end
ilong_hi = i-1;

for ilong = ilong_lo:ilong_hi;
    for ilat = ilat_lo:ilat_hi;
        g = togrid(lat(ilat),lon(ilong));
        iX = togridindex(g,long_hi - long_lo);
        monthcount = (yr_lo - input_lo) * 12 + 1;
        for iyr = yr_lo:yr_hi;      
            for m = 1:12;
                mystring = cellstr(strcat('x','/',num2str(m),'/',num2str(iyr)));
                qtr = toquarter(mystring);
                iY = toquarterindex(qtr,yr_lo);
                a = master{iX,iY};
                a{1} = num2cell(iX);
                q = toquarter(strcat('dd/',num2str(m),'/',num2str(iyr)));
                a{2} = q2q(q);
                a{3} = iyr;
                a{6} = tmp(ilong,ilat,monthcount);
                a{7} = a{7} + 1;
                a{15} = ilat;
                a{16} = ilong;
                if isnan(precip(ilong,ilat,monthcount)) == 0
                    if isempty(a(8)) == 1
                        a{8} = a{8} + precip(ilong,ilat,monthcount);
                    else a{8} = precip(ilong,ilat,monthcount);
                    end
                end
                % 1q temp lag
                a{13} = tmp(ilong,ilat,monthcount-4);
                % 1yr temp lag
                a{17} = tmp(ilong,ilat,monthcount-12);
                % 1q precip lag
                if isnan(precip(ilong,ilat,monthcount-4)) == 0
                    if isempty(a(14)) == 1
                        a{14} = a{14} + precip(ilong,ilat,monthcount-4);
                    else a{14} = precip(ilong,ilat,monthcount-4);
                    end
                end
                % 1yr precip lag
                if isnan(precip(ilong,ilat,monthcount-12)) == 0
                    if isempty(a(18)) == 1
                        a{18} = a{18} + precip(ilong,ilat,monthcount-12);
                    else a{18} = precip(ilong,ilat,monthcount-12);
                    end
                end
                
                % account for multiples in grid
%                 if isempty(a{8})
%                     a{8} = 0;
%                 end
%                 a{8} = a{8} + precip(ilong,ilat,monthcount);  % account for averaging?  
                
                
                master{iX,iY} = a;
                monthcount = monthcount + 1;
                pointer = [ilat ilong m iyr]
            end
        end
    end
end



%% Annual Time Fixed Effect Data

for i =1:grids
    for j = 1:quarters
        
        arr = master{i,j};
        iy = find(feyr==arr{3});
        arr{10} = gdp(iy);
        arr{11} = crop(iy);
        arr{12} = lstock(iy);
        arr{9} = growth(iy);
        arr{19} = nighlights(iy);
        arr{20} = lstock(iy);
        master{i,j} = arr;
        
    end
end


%% Final Spreadsheet
final_matrix = cell(grids*quarters,arraylength);
final_index = 1;
for i = 1:grids
    for j = 1:quarters
        ccell = master{i,j};
        
        for a_index = 1:arraylength
            output = ccell(a_index);

            final_matrix(final_index,a_index) = output;

            pointer2 = [i j a_index]
        end
        final_index = final_index + 1;
        
        
    end
end
%%


% grids in subrange:
subindex = 1;
for i = sublat_lo:sublat_hi
    for j = sublong_lo:sublong_hi
        g = togrid(i,j);
        gi = togridindex(g,long_hi-long_lo);
        subrange(subindex) = gi;
        subindex = subindex + 1;
    end
end
        
    




outi = 1;
for i = 1:grids*quarters
    x = final_matrix{i,1};
    if ismember(x{1}, celltracker);
        if ismember(x{1}, subrange);
            for j = 1:arraylength
                ccell = final_matrix{i,j};
                if iscell(ccell)
                    output_spread{outi,j} = cell2mat(ccell);
                else output_spread{outi,j} = ccell;
                end
            end
            outi = outi +1;
        end
    end
end

%%








    
    