function [X, t] = dataExtract(rawData, settingsSet, colsToKeep)

%Get list of column names from the loaded file
columnNames = rawData.Properties.VariableNames;

%Initialize selection vectors
keep = zeros(1,length(columnNames));
foundDateTime = 0;
dateOnly = 0;
timeOnly = 0;
foundGases = zeros(1,length(colsToKeep));

%Loop through reference file columns and selected gases to extract only important columns
for i =1:length(columnNames)
    
    %Get current column name (for code clarity)
    currentCol = columnNames{i};
    
    %----Check if column contains date and time info for alignment----
    if strcmpi(currentCol,'datetime')
        
        %Change variable name for easier referencing
        rawData.Properties.VariableNames{i}='datetime';
        
        %If already in datetime format, don't bother converting
        if(~isdatetime(rawData.datetime))
            %Try to convert the input datetime into datetime using default values and then values defined in the settingsSet structure
            try
                %Make temporary vector to try to convert datetime values
                tempdatetime=datetime(rawData.datetime);
                
                %Don't let it import weird dates
                flag = median(tempdatetime,'omitnan');
                assert(flag > datetime(1990,1,1) && flag < datetime(2100,1,1),'Issues reading datetime...');
                
                %If it succeeded, assign the dates into the table and clear temporary variable
                rawData.datetime=tempdatetime;
                clear tempdatetime
            catch err
                warning('Nonstandard date string detected');
                for j=1:length(settingsSet.datetimestrs)
                    try
                        %Don't make it keep trying if it's already converted
                        assert(~isdatetime(rawData.datetime),'Datetime converted succefully');
                        
                        %Same process as before
                        tempdatetime=datetime(rawData.datetime,'InputFormat',settingsSet.datetimestrs{j});
                        flag = median(tempdatetime,'omitnan');
                        
                        %Don't let it import weird dates
                        assert(flag > datetime(1990,1,1) && flag < datetime(2100,1,1),'Issues reading datetime...');
                        
                        %If it succeeded, write to table
                        rawData.datetime=tempdatetime;
                        clear tempdatetime
                    catch err
                    end
                end%Loop of nonstandard datetime strings to try
            end%Try/catch for datetime assignment
            
            %If the conversion didn't work, throw an error
            assert(isdatetime(rawData.datetime),'Datetime column not imported correctly');
        end%Datetime reading
        
        %Increment count of datetime columns found
        foundDateTime=foundDateTime+1;
        
        
        %----Try Unix/posix timestamps----
    elseif strcmpi(currentCol,'UNIX') || strcmpi(currentCol,'POSIX') 
    
        %Change variable name for easier referencing
        rawData.Properties.VariableNames{i}='datetime';
        
        %Convert from epoch time
        rawData.datetime = datetime(rawData.datetime,'ConvertFrom','posixtime');
        
        %Increment the foundDateTime - this allows it to throw an error if multiple datetime columns are found
        foundDateTime=foundDateTime+1;
        
        
        %----Allow for the use of separate time and date columns----
    elseif strcmpi(currentCol,'date') 
        
        rawData.Properties.VariableNames{i}='date';
        
        %Try to convert the date into datetime using default values and then values defined in the settingsSet structure
        try 
            rawData.date=datetime(rawData.date);
            dateOnly=i;
        catch err
            disp('Nonstandard date string detected, applying specified parse strings');
            for j=1:length(settingsSet.datestrings)
                try
                    rawData.date=datetime(rawData.date,'InputFormat',settingsSet.datestrings{j});
                    dateOnly=i;
                catch err
                end
            end
        end
        
    elseif strcmpi(currentCol,'time')
        rawData.Properties.VariableNames{i}='time';
        try %Try to convert the time into datetime using default values and then values defined in the settingsSet structure
            rawData.time=datetime(rawData.time);
            timeOnly=i;
        catch err
            disp('Nonstandard time stamp detected, applying specified parse strings');
            for j=1:length(settingsSet.timestrings)
                try
                    rawData.time=datetime(rawData.time,'InputFormat',settingsSet.timestrings{j});
                    timeOnly=i;
                catch err
                end
            end
        end
    else
        
        %----Check if column contains another variable marked to keep----
        for ii = 1:length(colsToKeep)
            if any(regexpi(currentCol,colsToKeep{ii}))
                keep(i)=1;
                foundGases(ii)=foundGases(ii)+1;
                %rawData.Properties.VariableNames{i}=colsToKeep{ii};
            end
        end
    end
end

%If no datetime or unix time variables were found, try to combine date and time variables
if (foundDateTime == 0) && (dateOnly > 0) && (timeOnly >0)
    rawData.datetime = rawData.date + timeofday(rawData.time);
    foundDateTime = 1;
end

%Check that everything was found okay
assert(foundDateTime==1,'Could not identify a singular date column when extracting data');
if any(foundGases~=1)
    errorMessage = strcat('Could not find the column for gas(es):',colsToKeep(foundGases==0));
    error(errorMessage{1});
end


%Return only columns that are in the sensed gas list
X=rawData(:,keep==1);

%Also return vector of datetimes for timeseries analysis
t = rawData.datetime;
end





