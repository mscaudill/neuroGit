%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2012  Matthew Caudill
%
%this program is free software: you can redistribute it and/or modify
%it under the terms of the gnu general public license as published by
%the free software foundation, either version 3 of the license, or
%at your option) any later version.

%this program is distributed in the hope that it will be useful,
%but without any warranty; without even the implied warranty of
%merchantability or fitness for a particular purpose.  see the
%gnu general public license for more details.

%you should have received a copy of the gnu general public license
%along with this program.  if not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ParPortTrigger
% This function is called by the stimulus generation gui (stimGen) and
% creates a TTL pulse on the serial port. We test for the operating system
% first so that we are compatible with either 32bit or 64 bit windows. In
% the latter case we will use a mex file written by some clever guys at
% USD. Please see link.
%
%http://apps.usd.edu/coglab/psyc770/IO64.html
%
%You will need those mex files if using a windows64 bit system
%
%This mex file is low level C++ code that gives us
% easy access to the LPT port ( we assume that the port has address 888 (
% the standard port). Note the operation of this function differs depending
% on the operating system it is being run on. For windows 32 bit, The
% function triggers pin 1 and a second pin may be connected to 18-25 of the
% serial port. If the os is 64 bit, you need to connect to the first data
% pin (pin 2) and one of the grounds. We will assign a value of 0 or 255
% for on/off to this pin.


% First we are going to set the priority level to the highest setting (2).
% This will increase the priority of this function so that it operates in
% real time (other options 0,1 are normal and high priority respectively).
% Note this is necessary becasue we are going to call the WaitSecs func
% which is most accurate if priority is set highest
Priority(2);

% Query for the operating system
currentOS = system_dependent('getos');

if strcmp(currentOS, 'Microsoft Windows XP')
    
    % As of version 2010a Matlab DAQ toolbox will no longer include a
    % parallel port adapter. It will however be available as a separate
    % download see:
    % http://www.mathworks.com/support/solutions/en/data/1-5LI9OA/index.html?pr
    % oduct=DA&solution=1-5LI9OA For now we will suppress the matlab
    % warning of this change
    warning('off', 'daq:digitalio:adaptorobsolete');
    
    % Construct a parallel port object
    parport = digitalio('parallel','LPT1');
    % Add pin 1 (index 0 on port ID 2), set the direction out and call it
    % the TrigLine see
    % http://www.mathworks.com/help/toolbox/daq/f11-17968.html#brdc5dg  for
    % help
    hwline = addline(parport,0,2,'out','TrigLine');
    % The pins on Port 2 defined as pins 1,14, 17 are hardware inverted so
    % 0 means ON and 1 means OFF
    TrigOn = 0;
    TrigOff = 1;
    % Get the parent object of the TrigLine
    parentobj = get(parport.TrigLine, 'parent');
    
    % IMPORTANT we are going to CACHE the parent obj using the class
    % uddobject below. WHY? Becasue caching speeds up the access of this
    % variable. This way the computer does have to go through the memory
    % bus to access this object from RAM but can get it from Virtual Memory
    parentuddobj = daqgetfield(parentobj,'uddobject');
    
    %%%%%%%%%%%%%%%%%%%%% ASSIGN VALS TO THE PARPORT OBJ
    %%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%
    % Initialize the pin to be OFF
    putvalue(parentuddobj,TrigOff);
    % Turn Trigger ON
    putvalue(parentuddobj,TrigOn);
    % wait for 2 us to give enough time to detect pulse (probably could be
    % smaller but lets be safe) (anyways wait secs has a 1ms error time
    % error)
    waitSecs(0.000002);
    % Return pin back to OFF state
    putvalue(parentuddobj,TrigOff);
    
    % Clean up the objects we've created
    delete(parport);
    clear parport;
    
elseif strcmp(currentOS, 'Microsoft Windows 7')
    
    % now we need to determine if 32 bit or 64 bit
    pcProcessorType = computer;
    
    % CASE 1 the processor architecture is 64 bit
    if strcmp(pcProcessorType, 'PCWIN64')
        
        % first create an input/output obj. using the mex file downloaded
        ioObj = io64;
    
        % interface to driver
        status = io64(ioObj);
    
        if status == 0 %Port is open and we are good to go
            % initialize the port to 0 value in case something was  on it
            initValue = 0;
            
            % set the port address to the standard '888' hexValue = 378
            address = 888;
            
            %write the initialization 0 to the port
            io64(ioObj,address,initValue);
            
            % now write the value of 255 to the port (turn all pins on)
            io64(ioObj,address, 255);
            
            % now we will wait for 1ms
            WaitSecs(.001)
            
            % finally set data back to 0;
            io64(ioObj,address,initValue);
            
            % WE CLEAR THE OBJECT FROM MEMORY
            clear ioObj
            clear io64
        end
        
        %CASE 2: the processor acrchitecture is 32 bit
    elseif strcmp(pcProcessorType, 'PCWIN')
        
        % first create an input/output obj. using the mex file downloaded
        ioObj = io32;
    
        % interface to driver
        status = io32(ioObj);
    
        if status == 0 %Port is open and we are good to go
            % initialize the port to 0 value in case something was  on it
            initValue = 0;
            
            % set the port address to the standard '888' hexValue = 378
            address = 888;
            
            %write the initialization 0 to the port
            io32(ioObj,address,initValue);
            
            % now write the value of 255 to the port (turn all pins on)
            io32(ioObj,address, 255);
            
            % now we will wait for 1ms
            WaitSecs(.001)
            
            % finally set data back to 0;
            io32(ioObj,address,initValue);
            
            % WE CLEAR THE OBJECT FROM MEMORY
            clear ioObj
            clear io32
        end
    end
end
    % Return Priority of the Matlab thread back to normal
    Priority(0);
end
