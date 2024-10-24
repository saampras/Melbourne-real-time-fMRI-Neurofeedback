%%
%Created and last edited by Saampras Ganesan on May 26, 2024
%%

%ROI PSC with confound
%TURN OFF BLUETOOTH IF ON
% Please use Backslash for file and folder names in WINDOWS!

% 6 s hemodynamic lag has 7.5 TRs - so consider lag of 7 TRs
% So, total minimum TRs removed from task block for feedback calculation = 7 TRs

% 1st is target ROI and 2nd is confound

sca;
clear all
global TR window scr_rect centreX centreY escapeKey start_time current_TBV_tr ROI_FC ROI_vals port_issue;


%% Needs change

TR = 

%Note: Folder\File names here should not have any numbers because it interferes
%with the rt_load_BOLD function

feedback_dir = [pwd];
feedback_file_name = 'NeuroFeedback_RunXX';
run_no = 0;


%% Do not change 

pp_no = 1;
pp_name = 'simulation 2';
num_blocks = 1; % Use 1
block_dur_TR = 15; % in TRs - at least 15
rest_dur_TR = 10; % in TRs - at least 15
cue_dur_TR = 5; % in TRs - Use 5
input('Press Enter to start >>> ','s'); %printing to command window

block_init = 0.5;
block = block_init;
current_TBV_tr = 1; %initializing

%For meditation and MW blocks
MW_blocks = 0;
med_blocks = 0;

med_block_timings = [];
rest_block_timings = [];
cue_timings = [];
FB_timings = [];
rest_blocks_mean = [];
rest_blocks_TRs = [];

ROI_FC = [];
port_issue = [];

fileID1 = fopen(fullfile([pwd '\Data\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) '_cue_timing.txt']), 'w');
fileID2 = fopen(fullfile([pwd '\Data\Participant_' num2str(pp_no)],['\' date '_pp_' num2str(pp_no) '_run_' num2str(run_no) '_block_timing.txt']), 'w');

%Writing to text files
PrintGeneralInfo(fileID1,date,pp_name,run_no,num_blocks,block_dur_TR);
PrintGeneralInfo(fileID2,date,pp_name,run_no,num_blocks,block_dur_TR);

fprintf(fileID1, '\n============================================================================\n');
fprintf(fileID1, '\n\n______________________________Cue timing information:__________________________');

fprintf(fileID2, '\n============================================================================\n');
fprintf(fileID2, '\n\n______________________________Block timing information:__________________________');

saveroot = [pwd '\Data\Participant_' num2str(pp_no) '\'];


%creating first feedback file (dummy)
dlmwrite([feedback_dir '\' feedback_file_name '-1.rtp'],[2,0,0,-1],'delimiter',' ');

try
    % Setup PTB with default value
    PsychDefaultSetup(1);
    
    % COMMENT OUT FOR ACTUAL EXPERIMENT - ONLY ON FOR TESTING
    Screen('Preference', 'SkipSyncTests', 1);
    
    % Get the screen number (primary or secondary)
    getScreens = Screen('Screens');
    ChosenScreen = min(getScreens); %choosing screen for display
    %ChosenScreen = max(getScreens); %choosing screen for display
    full_screen = [];
    
    % Getting screen luminance values
    white = WhiteIndex(ChosenScreen); %255
    black = BlackIndex(ChosenScreen); %0
    grey = white/2;
    magenta = [255 0 255];
    green = [0 255 0];
    
    % Open buffered screen window and color it black. scr_rect is a
    % rectange the size of the screen (1x4 array)
    [window, scr_rect] = PsychImaging('OpenWindow', ChosenScreen, black, full_screen);
    
    % Give PTB processing priority over other system and app processes
    Priority(MaxPriority(window));
    
    % Hide the mouse cursor
    HideCursor(window);
    
    % Get the coordinates of screen centre
    [centreX,centreY] = RectCenter(scr_rect);
    
    % Inter-frame interval
    ifi = Screen('GetFlipInterval',window);
    
    % Screen refresh rate
    hertz = FrameRate(window);
    
    
    % Define the keyboard keys that are listened for.
    
    KbName('UnifyKeyNames');
    escapeKey = KbName('ESCAPE');
    triggerKey = KbName('T'); %This is the trigger from the MRI
    
    
    %----------------------------------------------------------------------
    %Screen before trigger
    % FIRST CUE
    Text = 'A cross will appear now. \n \n Please look at the cross, \n and think whatever comes to mind freely. \n\n Press `t` to start.';
    Screen('TextSize',window,55);
    Screen('TextFont',window,'Arial');
    Screen('TextStyle',window,0);
    DrawFormattedText(window,Text,'center','center',magenta);
    Screen('Flip',window);
    
    %Reading Trigger
    KbTriggerWait(triggerKey);
    
    %creating second feedback file (dummy) after trigger
    dlmwrite([feedback_dir '\' feedback_file_name '-2.rtp'],[2,0,0,-1],'delimiter',' ');
    
    start_time = GetSecs();
    ROI_vals = [];
    
    fprintf(fileID1, '\nRun start time (MRI): \t\t%d \n', start_time);
    fprintf(fileID2, '\nRun start time (MRI): \t\t%d \n', start_time);
    current_TBV_tr = rt_load_BOLD(feedback_dir,feedback_file_name);
    fprintf(fileID1, '\nTBV start TR: \t\t%d \n', current_TBV_tr+1);%to start with TR=1
    fprintf(fileID2, '\nTBV start TR: \t\t%d \n', current_TBV_tr+1);
    
    %----------------------------------------------------------------------
    % cue start, cue end, cue duration
    fprintf(fileID1, '\n\n MRI Cue start     MRI Cue end     MRI Cue duration    TBV Cue start TR    TBV Cue end TR    TBV Cue duration TR \n\n');
    % block start, block end, block duration
    fprintf(fileID2, '\n\n MRI Block start     MRI Block end     MRI Block duration   TBV Block start TR    TBV Block end TR   TBV Block duration TR \n\n');
    %----------------------------------------------------------------------
    
    %% Baseline Rest period
    
    %duration would be 1 more than the difference between start
    %and end tr
    
    [block_start,block_end,block_dur,block_start_TR,block_end_TR,block_start_TBV_TR,block_end_TBV_TR] = DrawFixationCross(grey-50,rest_dur_TR,feedback_dir,feedback_file_name);  %dark grey
    rest_block_timings = [rest_block_timings;block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1];
    fprintf(fileID2,'%f  %f  %f  %f  %f  %f\n',[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]);
    rest_blocks_TRs = [rest_blocks_TRs;block_start_TR,block_end_TR]; %storing MRI TR for future calculation
    
    %Calculating Rest block's values
    rest_calc_start_TR = rest_blocks_TRs(end,1); % not considering a hemo lag here due to simulation
    baseline_lag_dur = 0; % not considering baseline delay here due to simulation 
    calc_interval = rest_calc_start_TR:rest_blocks_TRs(end,2);
    
    %ALL BOLD PSC values from dynamic ROI
    all_vals = ROI_vals(baseline_lag_dur+1:end,1); %Taking all the BOLD values so far, for cumulative GLM
    
    %Confound signal
    all_conf_vals = ROI_vals(baseline_lag_dur+1:end,2); %Taking all the confound ROI values so far, for cumulative GLM
    
    %Cumulative GLM - Regressing out detrended and demeaned confound from ROI so far
    [beta,~,stats] = glmfit(all_conf_vals-mean(all_conf_vals),all_vals);
    resid_BOLD = stats.resid + beta(1);
    rest_mean = mean(resid_BOLD(calc_interval-baseline_lag_dur)); %required mean is the residual mean withiin the rest block   
    rest_blocks_mean = rest_mean;
    
    
    % CUE
    Text = '---End of restful thinking---';
    [cue_start,~,~,cue_start_TR,~,cue_start_TBV_TR,~] = WriteInstruction(Text,magenta,cue_dur_TR-3,feedback_dir,feedback_file_name);
    Text = 'Soon, you will see an \ninstruction to meditate on screen.';
    [~,cue_end,~,~,cue_end_TR,~,cue_end_TBV_TR] = WriteInstruction(Text,white,cue_dur_TR-2,feedback_dir,feedback_file_name);
    cue_dur = cue_end - cue_start;
    cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
    fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
    
    %------------------------------------------------------------------   %% Start of task
    
    %% Meditation neurofeedback task
    current_TBV_tr = rt_load_BOLD(feedback_dir,feedback_file_name);
    ROI_vals;
    ROI_FC;
    med_blocks = med_blocks+1;
    trial_history = [];
    
    for i = 1:3
        % MEDITATION CUE
        if i==1 %Only for first time
            Text = 'To MEDITATE: \n\n Keep your eyes open. \n \n FOCUS on the sensations in \n your stomach area \n when the cross appears. \n\n Breathe normally as usual.';
            [cue_start,~,~,cue_start_TR,~,cue_start_TBV_TR,~] = WriteInstruction(Text,green,cue_dur_TR+2,feedback_dir,feedback_file_name);
            Text = 'You will see feedback of your\n performance after each meditation period';
            WriteInstruction(Text,white,cue_dur_TR-2,feedback_dir,feedback_file_name);
        end
        Text = 'Start meditating in:';
        WriteInstruction(Text,green,cue_dur_TR-3,feedback_dir,feedback_file_name);
        for countdown=3:-1:1
            Text = num2str(countdown);
            if countdown > 1
                WriteInstruction(Text,green,cue_dur_TR-4,feedback_dir,feedback_file_name);
            else
                [~,cue_end,~,~,cue_end_TR,~,cue_end_TBV_TR] = WriteInstruction(Text,green,cue_dur_TR-4,feedback_dir,feedback_file_name);
            end
        end
        cue_dur = cue_end - cue_start;
        cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
        fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
        
        % BLANK
        BlankOut(1,feedback_dir,feedback_file_name);
        
        % MEDITATION block FIXATION
        [block_start,block_end,block_dur,block_start_TR,block_end_TR,block_start_TBV_TR,block_end_TBV_TR] = DrawFixationCross(...
            grey-50,block_dur_TR,feedback_dir,feedback_file_name);  %dark grey
        fprintf(fileID2,'%f  %f  %f  %f  %f  %f\n',[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]);
        med_block_timings = [med_block_timings;[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]];
        
        % BLANK
        BlankOut(1,feedback_dir,feedback_file_name);
        
        % CUE
        Text = '---End of Meditation---';
        [cue_start,cue_end,cue_dur,cue_start_TR,cue_end_TR,cue_start_TBV_TR,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR-3,feedback_dir,feedback_file_name);
        cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
        fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
        
        % FEEDBACK BLOCK
        [feedback_start,feedback_end,feedback_dur,feedback_start_TR,feedback_end_TR,feedback_start_TBV_TR,feedback_end_TBV_TR,fb_rectangles] = DrawFeedback(...
            i,cue_dur_TR+5,feedback_dir,feedback_file_name,trial_history,block_start_TR,block_dur_TR); %MRI TR inputs
        trial_history(i,1) = fb_rectangles;
        fprintf(fileID2,'\n%f  %f  %f  %f  %f  %f\n\n',[feedback_start,feedback_end,feedback_dur,feedback_start_TBV_TR,feedback_end_TBV_TR,feedback_end_TBV_TR-feedback_start_TBV_TR+1]);
        FB_timings = [FB_timings;feedback_start,feedback_end,feedback_dur,feedback_start_TBV_TR,feedback_end_TBV_TR,feedback_end_TBV_TR-feedback_start_TBV_TR+1];
        
        % CUE
        Text = '---End of Feedback---';
        [cue_start,cue_end,cue_dur,cue_start_TR,cue_end_TR,cue_start_TBV_TR,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR-3,feedback_dir,feedback_file_name);
        cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
        fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
        
    end
    
    % BLANK
    BlankOut(1,feedback_dir,feedback_file_name);
    
    %----------------------------------------------------------------------
    %% End of run
    save([saveroot 'run_' num2str(run_no) '_rest_mean_values.mat'],'rest_blocks_mean');
    save([saveroot 'run_' num2str(run_no) '_FC_values.mat'],'ROI_FC');
    
    Text = ['Well done! \n You have completed the session. \n \n Press `escape` to exit :)'];
    [cue_start,cue_end,cue_dur,cue_start_TR,cue_end_TR,cue_start_TBV_TR,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR-2,feedback_dir,feedback_file_name);
    cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
    fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
    
    Total_run_duration = cue_start; %secs
    fprintf(fileID1, '\nTotal MRI run duration (s): \t\t%d \n', Total_run_duration);
    fprintf(fileID2, '\nTotal MRI run duration (s): \t\t%d \n', Total_run_duration);
    
    
    save([saveroot 'run_' num2str(run_no) '_workspace.mat']);
    
    %----------------------------------------------------------------------
    % To enable exit by pressing escape
    while(1)
        [pressed,when,keyCode,delta] = KbCheck([-1]);
        if pressed
            if keyCode(1,escapeKey)  %waits for escape from experimenter to close
                KbQueueRelease();
                sca;
                ShowCursor; %show mouse cursor
                break;
            else
                continue;
            end
        end
    end
    
catch
    sca;
    ShowCursor; %show mouse cursor
    psychrethrow(psychlasterror); %print error message to command window
end


%% FUNCTIONS

function PrintGeneralInfo(ID,d,name,rn,nb,bl)
% Writes general info for each participant session into text file
%
%ID - file ID
%d - date
%name - participant's name
%rn - run number
%nb - number of block sets (each block set = 3 meditation + 3 feedback
% + 1 rest trials
%bl - block length (in TR)

fprintf(ID, '\n============================================================================\n');
fprintf(ID, '\n______________________________General info:________________________________');
fprintf(ID, '\nDate of experiment: \t%s', d);
fprintf(ID, '\nParticipant Name: \t\t\t%s', name);
fprintf(ID, '\nRun number: \t\t%d', rn);
fprintf(ID, '\nNumber of Block sets per run: \t\t%d', nb);
fprintf(ID, '\nBlock Length [TR]: \t\t%f', bl);
end

%%%%%%%%%%%%%%%%%%%%%%

function [co,ce,cdur,block_start_tr,block_end_tr,block_start_tbv_tr,block_end_tbv_tr]=WriteInstruction(instruction,colour,num_trs,folder_path,file_prefix)
% Writes instruction on screen for specified duration
%
%INPUTS
%instruction - text input to display
%colour - colour of text to display
%num_trs - duration to keep the text on display (in TR)
%
%OUTPUTS
%co - onset time of text on screen (in s)
%ce - end time of text on screen (in s)
%cdur - duration of text on screen (in s)
%block_start_tr - onset of cue on screen (in TR)

global window start_time current_TBV_tr TR

co = GetSecs()- start_time;
Screen('TextSize',window,55);
Screen('TextFont',window,'Arial');
Screen('TextStyle',window,0);
DrawFormattedText(window,instruction,'center','center',colour);
Screen('Flip',window);
current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
block_start_tbv_tr = current_TBV_tr;
block_start_tr = round(co/TR)+1;
elapsed = (GetSecs() - start_time) - co;
while elapsed < (num_trs*TR)
    current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
    ce = GetSecs() - start_time;
    elapsed = ce - co;
end
cdur = elapsed;
block_end_tr = round(ce/TR);
block_end_tbv_tr = current_TBV_tr;
end

%%%%%%%%%%%%%%%%%%%%%%

function BlankOut(num_trs,folder_path,file_prefix)
% Shows a blank screen for a specified duration

%INPUTS
%num_trs - duration to display blank screen (in TR)
%folder_path - path to the feedback folder
%file_prefix - name of feedback file

global window current_TBV_tr start_time TR

starting = GetSecs() - start_time;
Screen('Flip',window);
current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
elapsed = (GetSecs() - start_time) - starting;
while elapsed < (num_trs*TR)
    current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
    elapsed = (GetSecs() - start_time) - starting;
end

end

%%%%%%%%%%%%%%%%%%%%%%

function [bo,be,bdur,block_start_tr,block_end_tr,block_start_tbv_tr,block_end_tbv_tr] = DrawFixationCross(colour,num_trs,folder_path,file_prefix)
% Draws a fixation cross for specified duration

%INPUTS
%colour - colour of fixation cross to display
%num_trs - duration to keep the cross on display (in TR)
%folder_path - path to the feedback folder
%file_prefix - name of feedback file

%OUTPUTS
%bo - onset time of fixation block (in s)
%be - end time of fixation block (in s)
%bdur - duration of fixation block (in s)
%block_start_tr - onset of cue on screen (in TR)
%block_vals - fMRI data from block (for each TR)

global TR window scr_rect centreX centreY start_time current_TBV_tr

bo = GetSecs() - start_time;
rect1_size = [0 0 scr_rect(4)/20 scr_rect(3)/4];
rect2_size = [0 0 scr_rect(3)/4 scr_rect(4)/20];
rect_color = colour;
rect1_coords = CenterRectOnPointd(rect1_size, centreX, centreY);
rect2_coords = CenterRectOnPointd(rect2_size, centreX, centreY);
Screen('FillRect',window,repmat(rect_color,[3,2]),[rect1_coords',rect2_coords']);
Screen('Flip',window);
current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
block_start_tbv_tr = current_TBV_tr;
block_start_tr = round(bo/TR)+1;
elapsed = (GetSecs() - start_time) - bo;
while elapsed < (num_trs*TR)
    current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
    be = GetSecs() - start_time;
    elapsed = be - bo;
end
bdur = elapsed;
block_end_tr = round(be/TR);
block_end_tbv_tr = current_TBV_tr;
end

%%%%%%%%%%%%%%%%%%%%%%


function [bo,be,bdur,feedback_strt_tr,feedback_end_tr,feedback_start_tbv_tr,feedback_end_tbv_tr,rect_num] = DrawFeedback(trial_number,num_trs,folder_path,file_prefix,feedback_history,Medtrial_start_tr,Medtrial_dur_tr)
% Displays the feedback screen for the specified duration

%INPUTS
%trial_number - which trial within the block set (1, 2 or 3)
%num_trs - duration to keep display the feedback (in TR)
%folder_path - path to the feedback folder
%file_prefix - name of feedback file
%feedback_history - feedback values (out of 20) of past trials within the block set (size [3 1])
%Medtrial_start_tr - onset of most recent meditation trial (in TR)
%Medtrial_dur_tr - duration of most recent meditation trial (in TR)

%OUTPUTS
%bo - onset time of feedback block (in s)
%be - end time of feedback block (in s)
%bdur - duration of feedback block (in s)
%feedback_strt_tr - onset of feedback block (in TR)
%rect_num - feedback value (out of 20) of the most recent meditation trial

global window scr_rect centreX centreY start_time current_TBV_tr TR
bo = GetSecs() - start_time;
current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
feedback_strt_tr = round(bo/TR)+1;
feedback_start_tbv_tr = current_TBV_tr;

%% Creating feedback bar to display current feedback
x_size = scr_rect(3)/15; %7.5 x_sizes on each half of screen (left and right)
y_size = scr_rect(4)/60; %30 y_sizes on each half of screen (top and bottom)
rect_size = [0 0 x_size y_size]; %size of each feedback rectangle
rect_color = [0 155 0]; %color of feedback rectangles - green

%NOTE: -y --> going UP from middle
%      +y --> going DOWN from middle
%      -x --> going LEFT from centre
%      +x --> going RIGHT from centre

all_rect_coords = zeros(4,20);
rect_start_pos = 3;
for i=1:20
    %Going up from -3 y_size to -22 y_size
    rect_coords = CenterRectOnPointd(rect_size, centreX, centreY - ((i+rect_start_pos-1)*y_size));
    all_rect_coords(:,i) = rect_coords';
end

%Marking a centre line above the 10th block
centre_line_pos = [centreX-(0.75*rect_size(3)),centreX+(0.75*rect_size(3));centreY-((rect_start_pos+9)*y_size)-(0.5*rect_size(4)),centreY-((rect_start_pos+9)*y_size)-(0.5*rect_size(4))];

%rect_num is the number of rectangles to color corresponding to the current feedback value
rect_num = calculate_feedback(Medtrial_start_tr,Medtrial_dur_tr);

%Fill rectangles with green based on current feedback value
Screen('FillRect',window,repmat(rect_color',[1,rect_num]),all_rect_coords(:,1:rect_num));

%Drawing frames for all 20 rectangles
Screen('FrameRect',window,255,all_rect_coords,ones(20,1)*1.5);

%Drawing the centre line on the feedback frame
Screen('DrawLines',window,centre_line_pos,2,200);

%% Creating recent performance history using line graph
%The line graph frame goes from from 7 y_size down to 28 y_size
side_edge_val = 5;
bottom_edge_val = 28;
top_edge_val = 8;

left_edge = centreX-(x_size*side_edge_val);
right_edge = centreX+(x_size*side_edge_val);
top_edge = centreY+(y_size*top_edge_val);
bottom_edge = centreY+(y_size*bottom_edge_val);

line_frame_vector = [left_edge,right_edge,left_edge,left_edge;bottom_edge,bottom_edge,bottom_edge,top_edge];

%Marking 20 lines within frame for each feedback increment
line_marking = zeros(2,20);

%20 lines go from 8 y_size down to 27 y_size.

for l = 1:20
    %Each line requires start and end coordinates [x1,x2;y1,y2]
    line_marking(:,(l*2-1):l*2) = [left_edge,right_edge;centreY+(y_size*(bottom_edge_val-l)),centreY+(y_size*(bottom_edge_val-l))];
end
middle_mark_line = [left_edge-(2*x_size),right_edge+(2*x_size);centreY+(y_size*(bottom_edge_val-10))-(0.5*y_size),centreY+(y_size*(bottom_edge_val-10))-(0.5*y_size)];
all_lines = [line_frame_vector,line_marking,middle_mark_line];
line_colors = [repmat(255,[3,4]),repmat(100,[3,40]),repmat(255,[3,2])]; %frame and middle line are white, other lines are grey
Screen('DrawLines', window, all_lines,2,line_colors);

feedback_history(trial_number,1) = rect_num; %storing current feedback value in history
if trial_number>1
    num_points = trial_number;
    circle_coordinates = zeros(4,num_points); %to draw circles on graph indicating average feedback value.
    circle_colors = zeros(3,num_points);
    line_join_coords = zeros(2,(num_points*2)-2); %to join the feedback circles with lines on the graph to depict change
    
    for c=1:num_points
        left = centreX-(x_size*(side_edge_val-(c*0.5*side_edge_val)-0.25));% equally spaced divisions along x-axis
        top = centreY+(y_size*(bottom_edge_val-feedback_history(c))-(0.5*y_size));
        right = centreX-(x_size*(side_edge_val-(c*0.5*side_edge_val)+0.25));
        bottom = centreY+(y_size*(bottom_edge_val-feedback_history(c))+(0.5*y_size));
        %diameters of oval are 0.5 x_size and 1 y_size
        
        circle_coordinates(:,c) = [left;top;right;bottom];
        
        %To join each feedback circle with lines to represent
        %change in performance over time
        if c>2
            line_join_coords(:,(c*2)-3) = line_join_coords(:,c-1);
            line_join_coords(:,(c*2)-2) = [(left+right)/2;(top+bottom)/2];
        else
            line_join_coords(:,c) = [(left+right)/2;(top+bottom)/2];
        end
        
        %Color the circles grey
        circle_colors(:,c) = [175;175;175];
    end
    
    Screen('DrawLines',window,line_join_coords,4,255); %white lines joining the circles
    Screen('FillOval',window,circle_colors,circle_coordinates);
    
end

%Writing text on screen
Screen('TextSize',window,45);
Screen('TextFont',window,'Arial');
Screen('TextStyle',window,0);
TextColor = 255;

label_1 = 'Most Focused';
label_2 = 'Least Focused';

%About current performance
Text1 = 'Recent performance';
Text1_pos = centreY - ((bottom_edge_val-1.5)*y_size); %changed recently
DrawFormattedText(window,Text1,'center', Text1_pos,TextColor);

label_1_color = [0 255 0];
label_2_color = [255 0 0];
label_1_pos = centreY - ((bottom_edge_val-4)*y_size); %changed recently
label_2_pos = centreY - ((rect_start_pos-3)*y_size);
Screen('TextSize',window,35);
DrawFormattedText(window,label_1,'center',label_1_pos,label_1_color);
DrawFormattedText(window,label_2,'center',label_2_pos,label_2_color);

%About performance history
Text2 = 'Performance History';
Text2_pos = centreY + (side_edge_val*y_size);
Screen('TextSize',window,45);
DrawFormattedText(window,Text2,'center', Text2_pos,TextColor);

label_1_pos_x = centreY - ((bottom_edge_val-3)*y_size);
label_1_pos_y = centreY+(top_edge_val*y_size);
label_2_pos_x = centreX-(x_size*(side_edge_val+2));
label_2_pos_y = centreY+(bottom_edge_val*y_size);
Screen('TextSize',window,35);
DrawFormattedText(window,label_1,label_1_pos_x,label_1_pos_y,label_1_color);
DrawFormattedText(window,label_2,label_2_pos_x,label_2_pos_y,label_2_color);


%% FEEDBACK DISPLAY

Screen('Flip',window);

elapsed = (GetSecs() - start_time) - bo;
while elapsed < (num_trs*TR)
    current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
    be = GetSecs() - start_time;
    elapsed = be - bo;
end
feedback_end_tr = round(be/TR);
feedback_end_tbv_tr = current_TBV_tr;
bdur = elapsed;

end

%%%%%%%%%%%%%%%%%%%%%%

function curr_tr = rt_load_BOLD(folder_path,file_prefix)
% Reads the most recent update in the feedback folder and updates the
% current TR (in a real-time scenario)

%For simulation, it just proceeds to the next TR

%INPUTS
%folder_path - path to the feedback folder
%file_prefix - name of feedback file

%OUTPUTS
%curr_tr - the current/present TR in TBV

global ROI_vals start_time TR port_issue

curr_time = GetSecs()-start_time;
curr_tr = round(curr_time/TR);
non_rounded = curr_time/TR;
TBV_tr = curr_tr; %in simulation

if (curr_tr>0) && abs(curr_tr-non_rounded)<0.005 %This is to ensure that it steps into the loop only after each TR and not during the TR
    tic;
    try
        %loading the feedback file info into temp1
        temp1 = load([folder_path '\' file_prefix '-' num2str(curr_tr) '.rtp']);
        temp2 = temp1(1,2); %current ROI psc value in temp2
        temp3 = temp1(1,end); %condition
        conf = temp1(1,3); %confound signal PSC
        source_flag = 0;
        
        %The below part is not important for simulation since simulations
        %are more predictable
    catch %storing previous values due to error in update
        port_issue = [port_issue;curr_tr];
        %Re-loading previous feedback file info into temp1
        temp1 = load([folder_path '\' file_prefix '-' num2str(curr_tr-1) '.rtp']);
        temp2 = temp1(1,2); %previous ROI psc value
        temp3 = temp1(1,end); %previous condition
        conf = temp1(1,3); %previous confound signal PSC
        source_flag = 1;
        
        if TBV_tr>1
            ROI_vals(TBV_tr-1,1:2) = [temp2,conf]; % Updating previous entry as well
            ROI_vals(TBV_tr-1,5) = temp3;
        end
        
    end
    elapsed = toc;
    %Current TR entry
    ROI_vals(TBV_tr,:) = [temp2,conf,TBV_tr,curr_time,temp3,elapsed,curr_tr,source_flag];
end
end

%%%%%%%%%%%%%%%%%%%%%%

function curr_feedback = calculate_feedback(medtrial_start,medtrial_dur)
% Calculates and returns the feedback value from the recent meditation trial

%INPUTS
%medtrial_start - onset of most recent meditation trial (in MRI TR)
%medtrial dur - duration of most recent meditation trial (in MRI TR)

%OUTPUTS
%curr_feedback - feedback value (out of 20) of the most recent meditation trial

global ROI_FC ROI_vals current_TBV_tr feedback_error

%Extracting PSC values for feedback estimation
num_TRs_for_calc = medtrial_dur - 7; %considering hemo lag of 7 TRs

last_tr = medtrial_start + medtrial_dur - 1;
first_tr = last_tr - num_TRs_for_calc + 1; %start of meditation trial after accounting for hemo delay
baseline_lag_dur = 5; % all calculations to start after these many TRs at the beginning of run

if first_tr < current_TBV_tr %TBV should have surpassed the first actual TR by now
    
    if (last_tr > current_TBV_tr) %If TBV has NOT covered all the necessary TRs by now
        last_tr = current_TBV_tr; %Use whatever the last TBV output TR is
    end
    
    %BOLD PSC values from target ROI 1
    med_vals_roi1 = ROI_vals(first_tr-baseline_lag_dur+1:last_tr-baseline_lag_dur+1,1);
    
    %BOLD PSC values from target ROI 2
    med_vals_roi2 = ROI_vals(first_tr-baseline_lag_dur+1:last_tr-baseline_lag_dur+1,2);
    
    %Calculating functional connectivity between roi1 and roi2
    [FC_val,~] = 
    
    %Feedback
    %Higher feedback value for higher FC value or vice-versa (as desired)
    curr_feedback =  
    
    %First term in ROI_FC is raw FC value 
    %Second term is for feedback
    ROI_FC = [ROI_FC;FC_val,curr_feedback,first_tr,last_tr]; %first and last TRs used for calculation
    
    if curr_feedback<1
        curr_feedback=1;
    elseif curr_feedback>20
        curr_feedback=20;
    end
    feedback_error = [feedback_error;0];
else
    curr_feedback = 1;
    feedback_error = [feedback_error;1];
end
end

%%%%%%%%%%%%%%%%%%%%%%
