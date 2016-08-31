
function SpecifyVariables
% CHOOSEVARIABLES structure and transforms the data in file 'filename' to a
% more usable form. Here, is where you specify the variables to be included
% in the model and whether they are fixed or random and whether thet are
% normal or log-normal.
% NOTE: you can add more variables from the original data by adding them in
% LoadData below.

% Global variables that are used by other functions. we recommend that you
% don't change this.
global CHOICEIDX CHOICE
global VAR_FX VAR_RD REP_VAR_RD N_FX N_RD LAB_RD LAB_FX
global NP SQRTNP NDRAWS
global I_BETA_FX I_BETA_RD I_DATA_FX I_DATA_RD

%%%%%%%%%% Prepare data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the data from 'filename' and save it to the structure D.
%
filename = 'rvu_data_workNH.csv';
D = LoadData(filename);

% Remove missing observations, mode choice 5 ('other') and year 2006
% You can prepare a short dataset for test purposes by using:
% DATA = RemoveObservations(DATA,{'short','20'});
D = RemoveObservations(D, {'mode','5','year','2006'} );

% Calculate choice vector.
[CHOICE , CHOICEIDX] = CalculateChoice(D);

D_IDX = D.Name;
DATA = D.Data;
NP = size(DATA,1);
SQRTNP = sqrt(NP);

%%%%%%%%%% Transform and Create Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Examples of transformed/created variable
% Some more alternatives can be found in the bottom of the file. If you
% want to add more, look in LoadData.
%

% General
ASC = ones(NP,1);% ASC = alternative specific constant
year=DATA(:,D_IDX.('year'));
dist=DATA(:, D_IDX.('dist_OK_m'))/10000; %distance (10km)

% Car
cartime=(1 - DATA(:, D_IDX.caracc))*4 ...
      + (year==2004).*DATA(:, D_IDX.('car_time_hi'))/60; %if no car, add 4h to car time
carcost=(16*(year==2004)).*dist; % distance-dependent cost, e.g. fuel


% Public Transport
PTcard = DATA(:, D_IDX.('pt_card_md'));
PTcost=((1-PTcard).*DATA(:, D_IDX.('pt_cash'))) +  15*PTcard;
PTauxt = DATA(:, D_IDX.('pt_aux_time_hi'))/60;   % access/egress time
%PTfwt  = DATA(:, D_IDX.('pt_fstwait_hi'))/60;    % first waiting time
PTinvt = DATA(:, D_IDX.('pt_invt_hi'))/60;       % in-vehicle time
PTtotwt = DATA(:, D_IDX.('pt_totwait_hi'))/60;   % total waiting time
PTtime = PTauxt + PTinvt + PTtotwt; % total travel time by public transport

%%%%%%%%%% Specify model %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specify which variables that should influence which mode
% Add more from the transformed variables above.
%

walk_data_fix = [ASC , dist];
walk_name_fix = {'Walk_ASC', 'Walk_distance'};

bike_data_fix = [ASC , dist];
bike_name_fix = {'Bike_ASC' , 'Bike_distance'};

car_data_fix = [ASC , cartime , carcost];
car_name_fix = {'Car_ASC' , 'Car_time' , 'cost'};

PT_data_fix = [PTtime ,  PTcost];
PT_name_fix = {'PT_time' , 'cost' }; % Observe that in the current specification, PT and car has the same cost-parameter.


% Specify when working with Mixed logit. Don't work for lab 1.
walk_data_rd = [];
walk_name_rd = {};
bike_data_rd = [];
bike_name_rd = {};
car_data_rd = [];
car_name_rd = {};
PT_data_rd = [];
PT_name_rd = {};
log_normal_var = {};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save index of variables for respectively mode and sort into fixed
% and random parameters.

name_fix = {walk_name_fix{:} , bike_name_fix{:} , car_name_fix{:} , PT_name_fix{:}};
VAR_FX = [walk_data_fix , bike_data_fix , car_data_fix , PT_data_fix]';

nwf = size(walk_data_fix,2); Iwf_data = 1:nwf;
nbf = size(bike_data_fix,2); Ibf_data = nwf + (1:nbf);
ncf = size(car_data_fix,2); Icf_data = nwf + nbf + (1:ncf);
npf = size(PT_data_fix,2); Ipf_data = nwf + nbf + ncf + (1:npf);

[LAB_FX , IA_fix , IC_fix] = unique(name_fix,'stable');
N_FX = length(IA_fix);
I_BETA_FX.walk = IC_fix(Iwf_data);
I_BETA_FX.bike= IC_fix(Ibf_data);
I_BETA_FX.car = IC_fix(Icf_data);
I_BETA_FX.PT = IC_fix(Ipf_data);
I_DATA_FX.walk = Iwf_data;
I_DATA_FX.bike = Ibf_data;
I_DATA_FX.car = Icf_data;
I_DATA_FX.PT = Ipf_data;

name_rd = {walk_name_rd{:} , bike_name_rd{:} , car_name_rd{:} , PT_name_rd{:}};
VAR_RD = [walk_data_rd , bike_data_rd , car_data_rd , PT_data_rd];
REP_VAR_RD = repmat(VAR_RD,1,NDRAWS);

nwr = size(walk_data_rd,2); Iwr_data = 1:nwr;
nbr = size(bike_data_rd,2); Ibr_data = nwr + (1:nbr);
ncr = size(car_data_rd,2); Icr_data = nwr + nbr + (1:ncr);
npr = size(PT_data_rd,2); Ipr_data = nwr + nbr + ncr + (1:npr);

[LAB_RD , IA_rd , IC_rd] = unique(name_rd,'stable');
N_RD = length(IA_rd);
I_BETA_RD.walk = IC_rd(Iwr_data);
I_BETA_RD.bike= IC_rd(Ibr_data);
I_BETA_RD.car = IC_rd(Icr_data);
I_BETA_RD.PT = IC_rd(Ipr_data);
I_DATA_RD.walk = Iwr_data;
I_DATA_RD.bike = Ibr_data;
I_DATA_RD.car = Icr_data;
I_DATA_RD.PT = Ipr_data;


end
function D = LoadData(filename)
% LOADDATA Loads the dataset from filename
%   D is a structure with the two fields 'Name' and 'Data'
%   D.Data is a matrix where the columns gives the different variables and
%   each person has a row.
%   D.Name is a structure with the fields 'var_name' such that
%   D.Name.var1 gives the column-index of var1 in the matrix D.Data
%   D.Data(D.Name.var1,:) thus gives the data for var1 for all individuals

DATA=load(filename);
[Nob, NV] = size(DATA);

% Field names of all variables in the data set
FIELD={'trip_id','indiv_id','ind_weight','trip_weight','year','mode',... % 1-6
      'toll_resp','toll_calc','toll_period','congest_categ',...   % 7-10
      'startt_halfh','orig_area3','dest_area3','Essinge_bypass',... % 11-14
      'age_grp06','age_grp04','foreign','male','single_househ',... % 15-19
      'househ_w_kids','no_children','own_drv_lic','no_househ_drv_lic',... % 20-23
      'caracc','no_hh_cars','no_emp_cars','envcar','car_md',... % 24-28
      'pt_card_md','hh_income_grp','cons_cap','occup','self_empl',... % 29-33
      'flext','park_poss_wp','cheap_parking_wp','company_car',... % 34-37
      'pt_subs_wp','dist_OK_m','car_time_hi','car_time_low',... % 38-41
      'pt_aux_time_hi','pt_fstwait_hi','pt_invt_hi','pt_cash',... % 42-45
      'pt_noboard_hi','pt_totwait_hi'}; % 46-47

% Create data structure to find a specific variable in FIELD using its name
for k = 1:NV;
      D_IDX.(FIELD{k}) = k;
end

% Define variables that are saved to the structure D. Observe that since only
% observations without missing values for any of these variables
% are used for estimation (see RemoveObservations), you should not add
% more variables than you want to use.
USE_VAR = {'age_grp04','no_househ_drv_lic','cons_cap','hh_income_grp','occup','car_md',...
      'cheap_parking_wp','self_empl','pt_noboard_hi','flext','househ_w_kids',...
      'no_children','own_drv_lic','single_househ','envcar','toll_calc','pt_card_md',...
      'dist_OK_m','car_time_hi','car_time_low','pt_invt_hi','pt_cash','park_poss_wp',...
      'caracc','company_car','orig_area3','pt_aux_time_hi','pt_fstwait_hi',...
      'pt_totwait_hi','pt_subs_wp','indiv_id','male','year','mode'};

NV_USE = length(USE_VAR);

DATA_OUT = zeros(Nob, NV_USE);
for k = 1:NV_USE
      DATA_OUT(: , k) = DATA(: , D_IDX.(USE_VAR{k}));
      D_IDX_OUT.(USE_VAR{k}) = k;
end

D = struct('Name',D_IDX_OUT,'Data',DATA_OUT);
end
function [CHOICE ,  CHOICEIDX] = CalculateChoice(D)
% CALCULATECHOICE Calculates the vector of CHOICEIDX such that
% P(CHOICEIDX(k)) is the probability of the observed choice for observation
% k in the likelihood-function.
D_IDX = D.Name;
DATA = D.Data;
CHOICE=DATA(:, D_IDX.('mode') ); % chosen mode
r=length(CHOICE);
rows=(1:r)';
CHOICEIDX=(CHOICE-1)*r + rows;
end


%%% EXAMPLE OF VARIABLES TO INCLUDE:
%     dlt2km   = logical(dist < 0.2);
%     dgt20km  = logical(dist > 2.0);
%     PTnoboard = DATA(:, D_IDX.('pt_noboard_hi'));
%     male = DATA(:, D_IDX.('male'));
%     inncity = DATA(:, D_IDX.('orig_area3')) == 1; % dummy for origin inside the toll ring, regardless of destination
%     parkposs = DATA(:, D_IDX.('park_poss_wp'));
%     compcar = DATA(:, D_IDX.('company_car'));
%     dst25km  = logical(dist >=0.2 & dist < 0.5);
%     dst510km = logical(dist >=0.5 & dist < 1.0); 
%     indiv_id = DATA(:, D_IDX.('indiv_id'));
%     age = DATA(:,D_IDX.('age_grp04'));
%     no_child = DATA(:, D_IDX.('no_children'));
%     income = DATA(:, D_IDX.('hh_income_grp'));
%     cons_cap = DATA(:, D_IDX.('cons_cap'));
%     occup = DATA(:, D_IDX.('occup'));
%     single_househ = DATA(:, D_IDX.('single_househ'));
%     househ_w_kids =  DATA(:, D_IDX.('househ_w_kids'));
%     caracc =  DATA(:, D_IDX.('caracc'));
%     self_empl = DATA(:, D_IDX.('self_empl'));
%     flext = DATA(:, D_IDX.('flext'));
%     cheappark = DATA(:, D_IDX.('cheap_parking_wp'));
%     PTsubs = DATA(:, D_IDX.('pt_subs_wp')); % public transport subsidies at workplace
%     envcar = DATA(:, D_IDX.('envcar'));
%     car_md = DATA(:, D_IDX.('car_md'));    
%     onlydrive = (nohhdl == 1).*(own_drv_lic==1);
%     nohhdl = DATA(:, D_IDX.('no_househ_drv_lic'));
%     own_drv_lic =  DATA(:, D_IDX.('own_drv_lic'));
%     mode = DATA(:, D_IDX.('mode')); %Chosen mode