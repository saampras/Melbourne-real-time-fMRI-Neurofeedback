%%
%Created and last edited by Saampras Ganesan on May 26, 2024
%%

%ROI PSC with confound - continuous
%TURN OFF BLUETOOTH IF ON
% Please use Backslash for file and folder names in WINDOWS!

% Hemodynamic lag needs to be considered implicitly by participant

% 1st is target ROI and 2nd is confound

sca;
clear all
global TR window scr_rect centreX centreY escapeKey start_time current_TBV_tr ROI_PSC ROI_vals PSC_thresh port_issue;


%% Needs Change

TR = 

%Note: Folder\File names here should not have any numbers because it interferes
%with the rt_load_BOLD function

feedback_dir = [pwd '\Data\NeuroFeedback_RunXX'];
feedback_file_name = 'NeuroFeedback_RunXX';
run_no = ;

%% Optional to change
block_dur_TR = 40; % in TRs - at least 20
rest_dur_TR = 15; % in TRs - at least 15
cue_dur_TR = 5; % in TRs - Use 5
PSC_thresh = -2; %This is the default value, can change if desired

%% Do not change

pp_no = 1;
pp_name = 'simulation 3';
num_blocks = 1; % Use 1
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

ROI_PSC = [];
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
    ROI_PSC;
    med_blocks = med_blocks+1;
    
    
    
    % MEDITATION CUE
    
    Text = 'To MEDITATE: \n\n Keep your eyes open. \n \n FOCUS on the sensations in \n your stomach area \n when the score bar appears. \n\n Breathe normally as usual.';
    [cue_start,~,~,cue_start_TR,~,cue_start_TBV_TR,~] = WriteInstruction(Text,green,cue_dur_TR+2,feedback_dir,feedback_file_name);
    Text = 'The feedback score will update as you meditate';
    WriteInstruction(Text,white,cue_dur_TR-2,feedback_dir,feedback_file_name);
    
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
    
    % MEDITATION + feedback
    [block_start,block_end,block_dur,block_start_TR,block_end_TR,block_start_TBV_TR,block_end_TBV_TR] = Meditation_feedback(...
        block_dur_TR,feedback_dir,feedback_file_name);  %dark grey
    fprintf(fileID2,'%f  %f  %f  %f  %f  %f\n',[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]);
    med_block_timings = [med_block_timings;[block_start,block_end,block_dur,block_start_TBV_TR,block_end_TBV_TR,block_end_TBV_TR-block_start_TBV_TR+1]];
    
    % BLANK
    BlankOut(1,feedback_dir,feedback_file_name);
    
    % CUE
    Text = '---End of Meditation---';
    [cue_start,cue_end,cue_dur,cue_start_TR,cue_end_TR,cue_start_TBV_TR,cue_end_TBV_TR] = WriteInstruction(Text,magenta,cue_dur_TR-3,feedback_dir,feedback_file_name);
    cue_timings = [cue_timings;cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1];
    fprintf(fileID1,'%f  %f  %f  %f  %f  %f\n\n',[cue_start,cue_end,cue_dur,cue_start_TBV_TR,cue_end_TBV_TR,cue_end_TBV_TR-cue_start_TBV_TR+1]);
    
    % BLANK
    BlankOut(1,feedback_dir,feedback_file_name);
    
    %----------------------------------------------------------------------
    %% End of run
    save([saveroot 'run_' num2str(run_no) '_rest_mean_values.mat'],'rest_blocks_mean');
    save([saveroot 'run_' num2str(run_no) '_TR_PSC_values.mat'],'ROI_PSC');
    
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

function [bo,be,bdur,block_start_tr,block_end_tr,block_start_tbv_tr,block_end_tbv_tr] = Meditation_feedback(num_trs,folder_path,file_prefix)
% Draws feedback for specified duration

%INPUTS
%num_trs - duration to keep the cross on display (in TR)
%folder_path - path to the feedback folder
%file_prefix - name of feedback file

%OUTPUTS
%bo - onset time of fixation block (in s)
%be - end time of fixation block (in s)
%bdur - duration of fixation block (in s)
%block_start_tr - onset of cue on screen (in TR)
%block_vals - fMRI data from block (for each TR)

global TR start_time current_TBV_tr

bo = GetSecs() - start_time;
current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
block_start_tbv_tr = current_TBV_tr;
block_start_tr = round(bo/TR)+1;
elapsed = (GetSecs() - start_time) - bo;
DrawFeedback();
while elapsed < (num_trs*TR)
    current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
    prev_tr = current_TBV_tr;
    while prev_tr == current_TBV_tr
        current_TBV_tr = rt_load_BOLD(folder_path,file_prefix);
    end
    DrawFeedback(); %Keep drawing feedback until block ends
    be = GetSecs() - start_time;
    elapsed = be - bo;
end
bdur = elapsed;
block_end_tr = round(be/TR);
block_end_tbv_tr = current_TBV_tr;
end

%%%%%%%%%%%%%%%%%%%%%%

function rect_num = DrawFeedback()
% Updates feedback screen based on latest score

%OUTPUT
%rect_num - feedback value (out of 20)

global window scr_rect centreX centreY

x_size = scr_rect(3)/15; %7.5 x_sizes on each half of screen (left and right)
y_size = scr_rect(4)/60; %30 y_sizes on each half of screen (top and bottom)
rect_size = [0 0 x_size y_size]; %size of each feedback rectangle
rect_color = [0 155 0]; %color of feedback rectangles - green

%NOTE: -y --> going UP from middle
%      +y --> going DOWN from middle
%      -x --> going LEFT from centre
%      +x --> going RIGHT from centre

all_rect_coords = zeros(4,20);
rect_start_pos = -10;
for i=1:20
    %Going up from -15 y_size to -34 y_size
    rect_coords = CenterRectOnPointd(rect_size, centreX, centreY - ((i+rect_start_pos-1)*y_size));
    all_rect_coords(:,i) = rect_coords';
end

%Marking a centre line above the 10th block
centre_line_pos = [centreX-(0.75*rect_size(3)),centreX+(0.75*rect_size(3));centreY-((rect_start_pos+9)*y_size)-(0.5*rect_size(4)),centreY-((rect_start_pos+9)*y_size)-(0.5*rect_size(4))];

%rect_num is the number of rectangles to color corresponding to the current feedback value
rect_num = calculate_feedback();

%Fill rectangles with green based on current feedback value
Screen('FillRect',window,repmat(rect_color',[1,rect_num]),all_rect_coords(:,1:rect_num));

%Drawing frames for all 20 rectangles
Screen('FrameRect',window,255,all_rect_coords,ones(20,1)*1.5);

%Drawing the centre line on the feedback frame
Screen('DrawLines',window,centre_line_pos,2,200);


%Writing text on screen
Screen('TextSize',window,35);
Screen('TextFont',window,'Arial');
Screen('TextStyle',window,0);
TextColor = 255;

label_1 = 'Most Focused';
label_2 = 'Least Focused';

label_1_color = [0 255 0];
label_2_color = [255 0 0];
label_1_pos = centreY - ((rect_start_pos+21)*y_size);
label_2_pos = centreY - ((rect_start_pos-3)*y_size);
Screen('TextSize',window,35);
DrawFormattedText(window,label_1,'center',label_1_pos,label_1_color);
DrawFormattedText(window,label_2,'center',label_2_pos,label_2_color);
Screen('Flip',window);



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
%curr_tr = round(curr_time/TR);
curr_tr = ceil(curr_time/TR);
non_rounded = curr_time/TR;
TBV_tr = curr_tr; %in simulation

%if (curr_tr>0) && abs(curr_tr-non_rounded)<0.005 %This is to ensure that it steps into the loop only after each TR and not during the TR
if curr_tr>0
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

function curr_feedback = calculate_feedback()
% Calculates and returns the feedback value

%INPUTS
%medtrial_start - onset of meditation trial (in MRI TR)

%OUTPUTS
%curr_feedback - feedback value (out of 20) for the current TR

global ROI_PSC PSC_thresh ROI_vals current_TBV_tr

baseline_lag_dur = 5; % all calculations to start after these many TRs at the beginning of run

%ALL BOLD PSC values from dynamic ROI
all_vals = ROI_vals(baseline_lag_dur:end,1); %Taking all the BOLD values so far, for cumulative GLM
%considering the initial lag

%All confound PSC from confound ROI mask
all_conf_vals = ROI_vals(baseline_lag_dur:end,2); %Taking all the confound mask values so far, for cumulative GLM

%Cumulative GLM - Regressing out detrended and demeaned confound from ROI so far
[beta,~,stats] = glmfit(all_conf_vals-mean(all_conf_vals),all_vals);
resid_BOLD = stats.resid + beta(1);

current_psc = 
current_conf = 0;

%Feedback value:
%Higher negative feedback value implies greater deactivation
%Convert negative feedback value to positive feedback value in the
%bar
% 0 and +ve PSC = feedback value of 1
% -ve PSC = feedback value above 1

curr_feedback =  % deactivation

%First term in ROI_PSC is unaffected by changing PSC threshold setting
%(direct from TBV)
%Second term is affected due to changing PSC threshold
ROI_PSC = [ROI_PSC;current_psc,curr_feedback,current_conf,current_TBV_tr]; %first and last TRs used for calculation

if curr_feedback<1
    curr_feedback=1;
elseif curr_feedback>20
    curr_feedback=20;
end

end


%%%%%%%%%%%%%%%%%%%%%%
