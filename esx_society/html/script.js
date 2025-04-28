var jobData = null;
var selectedIdentifier = null;
var selectedIsSecond = null;
var jobType = 'company';
var tempPrivData = {};
var tempConfigData = {};

Date.getUtcEpochTimestamp = () => Math.round(new Date().getTime() / 1000)

function HideEverything() {
	$('#wrap').hide();
	$('#wrap-settings').hide();
	$('#edit-rank-wrap').hide();
	$('#wrap-invite').hide();
	$('#wrap-myjobs').hide();
	$('#wrap-logs').hide();
	$('#wrap-privileges').hide();
	$('#wrap-abilities').hide();
}

function OnEmployeeSearch(event, isRewarding) {
	var searchStr = $("#search").val();
	
	$.post('http://esx_society/search', JSON.stringify({searchStr: searchStr, isRewarding: isRewarding}));
	
	event.preventDefault();
};

function ChangeView(action, isRewarding) {
	$.post('http://esx_society/change_view', JSON.stringify({action: action, isRewarding: isRewarding}));
}

function SelectAction(action) {
	switch(action) {
		case 'back':
			HideEverything();
			$('#wrap').fadeIn();
			
			break;
		case 'deposit':
			HideEverything();
			$.post('http://esx_society/deposit', JSON.stringify({}));
			
			break;
		case 'withdraw':
			HideEverything();
			$.post('http://esx_society/withdraw', JSON.stringify({}));
			
			break;
		case 'company-workers':
			$('#wrap').hide();
			$.post('http://esx_society/manage_employees', JSON.stringify({isRewarding: false}));
			
			break;
		case 'hire-worker':
			$('#wrap').hide();
			$.post('http://esx_society/hire', JSON.stringify({}));
			
			break;
		case 'single-reward':
			$('#wrap').hide();
			$.post('http://esx_society/manage_employees', JSON.stringify({isRewarding: true}));
			
			break;
		case 'mass-reward':
			HideEverything();
			$.post('http://esx_society/mass_reward', JSON.stringify());
			
			break;
		case 'set-meeting':
			HideEverything();
			$.post('http://esx_society/meeting', JSON.stringify({}));
			
			break;
		case 'display-workers':
			HideEverything();
			$.post('http://esx_society/display_workers', JSON.stringify({}));
			
			break;
		case 'warehouse-open':
			HideEverything();
			$.post('http://esx_society/warehouse', JSON.stringify({status: true}));
			
			break;
		case 'warehouse-close':
			HideEverything();
			$.post('http://esx_society/warehouse', JSON.stringify({status: false}));
			
			break;
		case 'company-logs':
			$('#wrap').hide();
			$.post('http://esx_society/company_logs', JSON.stringify());
			
			break;
		case 'company-privileges':
			$('#wrap').hide();
			$.post('http://esx_society/company_privileges', JSON.stringify());
			
			break;
		case 'abilities':
			$('#wrap').hide();
			$.post('http://esx_society/police_abilities', JSON.stringify({}));
			
			break;
		case 'rank-up':
			$('#wrap').hide();
			$.post('http://esx_society/rank_up', JSON.stringify({}));
			
			break;	
			
			
			
		default:
			console.log('default')
	}
}

function SelectRank(grade) {
	$('#edit-rank-wrap').hide();
	$.post('http://esx_society/select_rank', JSON.stringify({identifier: selectedIdentifier, grade: grade, isSecondJob: selectedIsSecond}));
}

function EditRank(identifier, isSecondJob) {
	selectedIdentifier = identifier;
	selectedIsSecond = isSecondJob;
	
	$('#edit-rank-wrap').fadeIn();
}

function KickFromJob(identifier, isSecondJob,isPreviousJob) {
	$.post('http://esx_society/fire', JSON.stringify({identifier: identifier, isSecondJob: isSecondJob, isPreviousJob: isPreviousJob}));
}

function GiveReward(identifier) {
	$.post('http://esx_society/reward', JSON.stringify(identifier));
}

function InviteToJob(id) {
	$.post('http://esx_society/invite', JSON.stringify(id));
}

function SetupGrades(grades) {
	let temp = `<div id="edit-rank-wrap">`;
	
	for (let i = 0; i < grades.length; i++) {
		temp += `<button onclick = "SelectRank(`+ grades[i].grade +`)" id="`+ grades[i].grade +`" class="change-rank">`+ grades[i].label +`</button>`;
	}
	
	temp += `</div>`;
	
	return temp
}

function TimestampToDate(timestamp, isConnected) {
	if (timestamp > 0 && !isConnected) {
		let date = new Date(timestamp * 1000);
		return (date.toLocaleDateString("el-GR")+ ' ' +date.toLocaleTimeString("el-GR"))
	}
	else if (isConnected) {
		return 'NOW';
	}
	
	return 'NEVER';
}

function ManageEmployees(employees) {
	let gradesHtml = SetupGrades(jobData.grades);
	
	$('#change-view').html(`
		<tr>
			<td>
				<form action="">
				  <input type="search" id="search" name="search" placeholder="Search.." required>
				  <button type="submit" onclick="OnEmployeeSearch(event, false)" id="btn-search"><i class="fas fa-search"></i></button>
				</form>
			</td>
			<td><button onclick="ChangeView('online', false)" id="btn-online">Online</button></td>
			<td><button onclick="ChangeView('offline', false)" id="btn-offline">Offline</button></td>
			<td><button onclick="ChangeView('everybody', false)" id="btn-everybody">Everybody</button></td>
			<td style="padding-left:0.2vw;vertical-align:middle;font-size:0.7vw;">TOTAL MEMBERS<br/> <span id="total-members">`+ employees.length +` People</span></td>
		</tr>`
	);
	
	$('#manage-employees').html('');
	
	for (let i = 0; i < employees.length; i++) {
		let dayOnlineHtml = '00:00:00';
		
		if (employees[i].day_online > 0) {
			dayOnlineHtml = new Date(employees[i].day_online * 1000).toISOString().substr(11, 8);
		}
		
		let totalOnlineHtml = '00:00:00';
		
		if (employees[i].total_online > 0) {
			totalOnlineHtml = new Date(employees[i].total_online * 1000).toISOString().substr(11, 8);
		}
		
		let lastConnectHtml = TimestampToDate(employees[i].lastaction, employees[i].isConnected);
		let memberStatus = (employees[i].isConnected) ? "member-status-on" : "member-status-off";
		
		$('#manage-employees').append(`
			<tr>
				<td class="strain-row" style="width:3%"><div id=`+ memberStatus +`></div></td>
				<td class="strain-row" style="width:10%"><span id="member-id">`+ employees[i].id +`</span></td>
				<td class="strain-row" style="width:25%"><span id="member-name">`+ employees[i].name +`</span></td>
				<td class="strain-row" style="width:20%">
					<span id="member-rank">
						`+ employees[i].job.grade_label +`
						`+ gradesHtml +`
					</span>
				</td>
				<td class="strain-row">
					<div id="member-online">ONLINE TODAY: <span id="today-online">`+ dayOnlineHtml +`</span></div>
					<div id="member-online">TOTAL TIME ONLINE: <span id="weekly-online">`+ totalOnlineHtml +`</span></div>
					<div id="member-online">LAST ONLINE: <span id="last-online">`+ lastConnectHtml +`</span></div>
				</td>
				<td class="strain-row" style="width:12%">
				<button onclick = "KickFromJob(\'`+ employees[i].identifier +`\', `+ employees[i].isSecondJob +`, `+ employees[i].isPreviousJob+`)" id="btn-kick"><i class="fal fa-sign-out-alt"></i> Dismiss</button><br/>
				<button onclick = "EditRank(\'`+ employees[i].identifier +`\', `+ employees[i].isSecondJob +`)" id="btn-edit-rank"><i class="fal fa-user-edit"></i> Edit Rank</button>
				</td>
			</tr>`
		);
	}
	
	//$('#company-level').html(`COMPANY LEVEL<br/><span>`+ jobData.rank +`</span>`);
	//$('#company-rank-pts').html(`RANK POINTS<br/><span>`+ jobData.experience +`</span><br/><button id="btn-rank-up"><i class="fas fa-angle-double-up"></i> RANK UP</button>`);
}

function RewardEmployee(employees) {
	$('#change-view').html(`
		<tr>
			<td>
				<form action="">
				  <input type="search" id="search" name="search" placeholder="Search.." required>
				  <button type="submit" onclick="OnEmployeeSearch(event, true)" id="btn-search"><i class="fas fa-search"></i></button>
				</form>
			</td>
			<td><button onclick="ChangeView('online', true)" id="btn-online">Online</button></td>
			<td><button onclick="ChangeView('offline', true)" id="btn-offline">Offline</button></td>
			<td><button onclick="ChangeView('everybody', true)" id="btn-everybody">Everybody</button></td>
			<td style="padding-left:0.2vw;vertical-align:middle;font-size:0.7vw;">TOTAL MEMBERS<br/> <span id="total-members">`+ employees.length +` People</span></td>
		</tr>`
	);
	
	$('#manage-employees').html('');
	
	for (let i = 0; i < employees.length; i++) {
		let dayOnlineHtml = '00:00:00';
		
		if (employees[i].day_online > 0) {
			dayOnlineHtml = new Date(employees[i].day_online * 1000).toISOString().substr(11, 8);
		}
		
		let totalOnlineHtml = '00:00:00';
		
		if (employees[i].day_online > 0) {
			totalOnlineHtml = new Date(employees[i].total_online * 1000).toISOString().substr(11, 8);
		}
		
		let lastConnectHtml = TimestampToDate(employees[i].lastaction, employees[i].isConnected);
		let memberStatus = (employees[i].isConnected) ? "member-status-on" : "member-status-off";
		
		$('#manage-employees').append(`
			<tr>
				<td class="strain-row" style="width:3%"><div id=`+ memberStatus +`></div></td>
				<td class="strain-row" style="width:10%"><span id="member-id">`+ employees[i].id +`</span></td>
				<td class="strain-row" style="width:25%"><span id="member-name">`+ employees[i].name +`</span></td>
				<td class="strain-row" style="width:20%">
					<span id="member-rank">
						`+ employees[i].job.grade_label +`
					</span>
				</td>
				<td class="strain-row">
					<div id="member-online">ONLINE TODAY: <span id="today-online">`+ dayOnlineHtml +`</span></div>
					<div id="member-online">TOTAL TIME ONLINE: <span id="weekly-online">`+ totalOnlineHtml +`</span></div>
					<div id="member-online">LAST ONLINE: <span id="last-online">`+ lastConnectHtml +`</span></div>
				</td>
				<td class="strain-row" style="width:12%"><button onclick = "GiveReward(\'`+ employees[i].identifier +`\')" id="btn-reward"><i class="fas fa-gift"></i> Reward</button></td>
			</tr>`
		);
	}
	
	//$('#company-level').html(`COMPANY LEVEL<br/><span>`+ jobData.rank +`</span>`);
	//$('#company-rank-pts').html(`RANK POINTS<br/><span>`+ jobData.experience +`</span>`);
	//$('#company-rank-pts').html(`RANK POINTS<br/><span>`+ jobData.experience +`</span><br/><button id="btn-rank-up"><i class="fas fa-angle-double-up"></i> RANK UP</button>`);
}

function ManageHireList(playerList) {
	$('#manage-employees2').html('');
	
	for (let i = 0; i < playerList.length; i++) {
		let imagelink = `https://nui-img/` + playerList[i].mugshot +`/` + playerList[i].mugshot +`?t=` + Date.getUtcEpochTimestamp()
		
		$('#manage-employees2').append(`
			<tr>
				<td class="strain-row" style="width:3%"><div id="member-status-on"></div></td>
				<td class="strain-row" style="width:10%;"><span id="member-id">`+ playerList[i].player +`</span></td>
				<td class="strain-row" style="width:8%;text-align:center;"><img id="member-profile" src=`+ imagelink +`/></td>
				<td class="strain-row" style="width:25%"><span id="member-name">`+ playerList[i].name +`</span></td>
				<td class="strain-row" style="width:10%;font-size:0.8vw;">BATTLEPASS LEVEL</td>
				<td class="strain-row" style="width:7%"><div id="member-pass-level">`+ playerList[i].level +`<br/><span>LEVEL</span></div></td>
				<td class="strain-row" style="width:10%"><button onclick="InviteToJob(`+ playerList[i].player +`)" id="btn-invite"><i class="fas fa-user-plus"></i> Invite</button></td>
			</tr>`
		);
	}
}

function ShowGpsLocation(job) {
	HideEverything();
	$.post('http://esx_society/gps_location', JSON.stringify(job));
}

function ChangeJob(job) {
	HideEverything();
	$.post('http://esx_society/change_job', JSON.stringify(job));
}

function SetupMyJobs(jobs) {
	$('#manage-jobs').html('');
	
	for (let i = 0; i < jobs.length; i++) {
		if (jobs[i].isPrev){
			$('#manage-jobs').append(`
			<tr>
				<td class="strain-row" style="width:8%;"><div id="job-icon"><center><i class="far fa-briefcase"></i></center></div></td>
				<td class="strain-row" style="width:20%;"><div id="job-name">`+ jobs[i].label +`</div></td>
				<td class="strain-row" style="width:30%;"><div id="previous-job"><i class="fal fa-history"></i> Previous Job</div></td>
				<td class="strain-row" style="width:15%;"><button onclick="ChangeJob(\'`+ jobs[i].name +`\')" id="btn-change-job"><i class="fas fa-random"></i> Change Job</button></td>
			</tr>`
		);
		}else{
			$('#manage-jobs').append(`
			<tr>
				<td class="strain-row" style="width:8%;"><div id="job-icon"><center><i class="far fa-briefcase"></i></center></div></td>
				<td class="strain-row" style="width:20%;"><div id="job-name">`+ jobs[i].label +`</div></td>
				<td class="strain-row" style="width:30%;"><div id="current-job"><i class="fas fa-badge-check"></i> Job Boss</div></td>
				<td class="strain-row" style="width:15%;"><button onclick="ChangeJob(\'`+ jobs[i].name +`\')" id="btn-change-job"><i class="fas fa-random"></i> Change Job</button></td>
			</tr>`
		);
		}
		
	}
}

function ChangeLogView(event) {
	var searchStr = $("#search-log").val();
	
	$.post('http://esx_society/search_log', JSON.stringify({searchStr: searchStr, shouldReset: false}));
	event.preventDefault();
};

function ResetLogView() {
	$.post('http://esx_society/search_log', JSON.stringify({searchStr: '', shouldReset: true}));
}

function SetupLogs(logs) {
	$('#display-logs').html('');
	
	$('#change-logs-view').html(`
		<tr>
			<td>
				<form action="">
				  <input type="search" id="search-log" name="search" placeholder="Search.." required>
				  <button type="submit" onclick="ChangeLogView(event)" id="btn-search-log"><i class="fas fa-search"></i></button>
				</form>
			</td>
			<td><button onclick="ResetLogView()" id="btn-everybody">Reset Search</button></td>
		</tr>`
	);
	
	for (let i = 0; i < logs.length; i++) {
		$('#display-logs').append(`
			<tr>
				<td class="strain-row" style="width:3%"><div id="member-status-on"></div></td>
				<td class="strain-row" style="width:10%"><span id="member-id">`+ logs[i].pid +`</span></td>
				<td class="strain-row" style="width:25%"><span id="member-name">`+ logs[i].name +`</span></td>
				<td class="strain-row" style="width:33%"><div id="member-action"><span>`+ logs[i].action +`</span> ON <span>`+ TimestampToDate(logs[i].timestamp, false) +`</span></div></td>
			</tr>`
		);
		
		/*if (logs[i].deposit == 1) {
			$('#display-logs').append(`
				<tr>
					<td class="strain-row" style="width:3%"><div id="member-status-on"></div></td>
					<td class="strain-row" style="width:10%"><span id="member-id">`+ logs[i].pid +`</span></td>
					<td class="strain-row" style="width:25%"><span id="member-name">`+ logs[i].name +`</span></td>
					<td class="strain-row" style="width:33%"><div id="member-deposit">DEPOSITED: <span>`+ logs[i].item +`</span> ON <span>`+ TimestampToDate(logs[i].timestamp, false) +`</span></div></td>
				</tr>`
			);
		}
		else {
			$('#display-logs').append(`
				<tr>
					<td class="strain-row" style="width:3%"><div id="member-status-on"></div></td>
					<td class="strain-row" style="width:10%"><span id="member-id">`+ logs[i].pid +`</span></td>
					<td class="strain-row" style="width:25%"><span id="member-name">`+ logs[i].name +`</span></td>
					<td class="strain-row" style="width:33%"><div id="member-withdraw">WITHDREW: <span>`+ logs[i].item +`</span> ON <span>`+ TimestampToDate(logs[i].timestamp, false) +`</span></div></td>
				</tr>`
			);
		}*/
	}
}

function SetupGradePrivileges(grade, data) {
	let temp = '';
	
	for (let i = 0; i < data.length; i++) {
		let name = tempConfigData[i].name;
		let label = tempConfigData[i].label;
		let privId = `pr-${grade}-${name}`;
		
		if (data[i]) {
			temp += `<div class="privilege-item">
						<input id="`+ privId +`" type="checkbox" class="css-checkbox" checked="checked"/>
						<label for="`+ privId +`" class="css-label">`+ label +`</label>
					</div>`;
		}
		else {
			temp += `<div class="privilege-item">
						<input id="`+ privId +`" type="checkbox" class="css-checkbox"/>
						<label for="`+ privId +`" class="css-label">`+ label +`</label>
					</div>`;
		}
	}
	
	return temp;
}

function SavePrivileges(grade) {
	let privileges = {};
	
	for (let i = 0; i < tempPrivData[grade].length; i++) {
		let name = tempConfigData[i].name;
		let privId = `pr-${grade}-${name}`;
		privileges[name] = $(`#${privId}`).is(':checked');
	}
	
	$.post('http://esx_society/save_privileges', JSON.stringify({grade: grade, privileges: privileges}));
}

function ResetPrivileges(grade) {
	$.post('http://esx_society/save_privileges', JSON.stringify({grade: grade}));
}

function SetupPrivileges(privileges, config) {
	$('#manage-privileges').html('');
	
	tempPrivData = {};
	tempConfigData = config;
	
	for (let i = 0; i < privileges.length; i++) {
		let grade = privileges[i].grade;
		let data = privileges[i].data;
		let gradePrivileges = SetupGradePrivileges(grade, data);
		
		tempPrivData[grade] = data;
		
		$('#manage-privileges').append(`
			<tr>
				<td class="strain-row" style="width:17%;"><span id="privilege-name">`+ jobData.grades[grade].label +`</span></td>
				<td class="strain-row" style="width:55%;" id="privileges-${grade}">
					`+ gradePrivileges +`
				</td>
				<td class="strain-row" style="width:25%;text-align:center;">
					<button onclick="SavePrivileges(`+ grade +`)" id="btn-save"><i class="fal fa-save"></i> Save</button><br/>
					<button onclick="ResetPrivileges(`+ grade +`)" id="btn-reset"><i class="far fa-redo-alt"></i> Reset</button>
				</td>
			</tr>`
		);
	}
}

function UpgradeAbility(name) {
	if (tempPointsLeft >= jobData.apr) {
		$.post('http://esx_society/upgrade_ability', JSON.stringify(name));
	}
}

function IncreaseRank() {
	HideEverything();
	$.post('http://esx_society/increase_rank', JSON.stringify());
}

function ResetAbilities() {
	HideEverything();
	$.post('http://esx_society/reset_abilities', JSON.stringify());
}

function SetupAbilities(abilities, config) {
	tempPointsLeft = 0;
	
	let usedPoints = 0;
	let points = jobData.rank*jobData.apr;
	let experience = (jobData.experience < jobData.epr) ? (jobData.experience) : (jobData.epr);
	
	$('#statistics-list').html('');
	
	for (let i = 0; i < config.length; i++) {
		let value = (abilities[config[i].name] != null) ? (abilities[config[i].name]) : (0);
		usedPoints += value;
		
		$('#statistics-list').append(`
			<tr>
				<td class="icon-`+ config[i].color +`"><i class="`+ config[i].icon +`"></i></td>
				<td class="text">
					<span id="title">`+ config[i].label +`</span>
					<span id="skill-description"><i class="far fa-question-square"></i><span class="tooltiptext">`+ config[i].text +`</span></span>
				</td>
				<td class="pbar"><div class="w3-border"><div class="w3-`+ config[i].color +`" style="width:`+ value +`%"></div></div></td>
				<td class="green">`+ value +`%</td>
				<td class="button"><button onclick="UpgradeAbility(\'`+ config[i].name +`\')" id="upgrade-ability">UPGRADE</button></td>
			</tr>
		`);
	}
	
	tempPointsLeft = points - usedPoints*jobData.apr/jobData.ppa;
	
	$('#police-level').html(`
		<center><div id="levelbar"></div></center>
		<script>
		var bar = new ProgressBar.Circle(levelbar, {
		  strokeWidth: 10,
		  color: 'rgba(255,255,255,0.1)',
		  trailColor: 'rgba(255,255,255,0.2)',
		  trailWidth: 1,
		  easing: 'easeInOut',
		  duration: 2000,
		  svgStyle: null,
		  text: {
			value: '',
			alignToBottom: false
		  },
		  
		  step: (state, bar) => {
			bar.path.setAttribute('stroke', state.color);
			var value = Math.round(bar.value() * 100);
			bar.setText("<span id='level-circle'>`+ jobData.rank +`</span><br/><span id='level-circle-desc'>LEVEL</span>");
			bar.text.style.color = state.color;
		  }
		});
		
		bar.animate(`+ experience +` / `+ jobData.epr +`);
		</script>
		<br/>
		POLICE LEVEL<br/>
		<span id="perk-rank">LEVEL `+ jobData.rank +`</span><br/>
		POLICE ABILITY POINTS: <span id="rank-coins">`+ tempPointsLeft.toFixed(1) +`</span><br/>
		
		<br/>
		<button onclick="IncreaseRank()" id="increase-rank"><i class="fas fa-arrow-up"></i> INCREASE RANK</button>
		<button onclick="ResetAbilities()" id="reset-abilities"><i class="fas fa-redo"></i> RESET ABILITIES</button>
	`);
}

$(function() {
	window.addEventListener('message', function(event) {
		if (event.data.action == 'show') {
			jobData = event.data.job;
			
			if (jobData.name == 'police') {
				jobType = 'police';
				
				$('#company-name-big').css('color', 'rgb(26, 223, 255)');
				$('#company-name-big').css('text-shadow', 'rgb(0, 81, 203) 0px 0px 40px');
				
				$('#police-abilities').show();
				$('#company-level').show();
				$('#company-rank-pts').show();
			}
			else if (jobData.name == 'ambulance') {
				jobType = 'ems';
				
				$('#company-name-big').css('color', 'rgb(255, 48, 48)');
				$('#company-name-big').css('text-shadow', 'rgb(203, 0, 0) 0px 0px 40px');
				
				$('#police-abilities').hide();
				$('#company-level').hide();
				$('#company-rank-pts').hide();
			}
			else {
				jobType = 'company';
				
				$('#company-name-big').css('color', 'rgb(255, 216, 26)');
				$('#company-name-big').css('text-shadow', 'rgb(187, 86, 0) 0px 0px 40px');
				
				$('#police-abilities').hide();
				$('#company-level').hide();
				$('#company-rank-pts').hide();
			}
			
			$('#company-name-big').html(jobData.label);
			
			$('#company-level').html(`COMPANY LEVEL<br/><span>`+ jobData.rank +`</span>`);
			$('#company-rank-pts').html(`RANK POINTS<br/><span>`+ jobData.experience +`/`+ jobData.epr +`</span><br/><button onclick = "SelectAction('rank-up')" id="btn-rank-up"><i class="fas fa-angle-double-up"></i> RANK UP</button>`);
			$('#boss-name').html(`ORIGINAL BOSS<br/><span>`+ jobData.bossName +`</span>`);
			$("#society-money-title").html(`SOCIETY MONEY <span class="society-money-value">`+'$'+jobData.societyMoney+`</span>`);
			$('#viceboss-name').html(`VICEBOSS<br/><span>`+ jobData.vicebossName +`</span>`);
			
			$('#wrap').css('background-image', `url('../html/images/`+ jobType +`-background.png')`);
			
			$('#deposit').css('background-image', `url('../html/images/`+ jobType +`-deposit.png')`);
			$('#withdraw').css('background-image', `url('../html/images/`+ jobType +`-withdraw.png')`);
			$('#company-workers').css('background-image', `url('../html/images/`+ jobType +`-workers.png')`);
			$('#hire-worker').css('background-image', `url('../html/images/`+ jobType +`-hire-worker.png')`);
			$('#single-prizes').css('background-image', `url('../html/images/`+ jobType +`-single-prizes.png')`);
			$('#mass-prizes').css('background-image', `url('../html/images/`+ jobType +`-mass-prizes.png')`);
			$('#display-workers').css('background-image', `url('../html/images/`+ jobType +`-display-workers.png')`);
			$('#set-meeting').css('background-image', `url('../html/images/`+ jobType +`-set-meeting.png')`);
			$('#warehouse-open').css('background-image', `url('../html/images/`+ jobType +`-warehouse-open.png')`);
			$('#warehouse-close').css('background-image', `url('../html/images/`+ jobType +`-warehouse-close.png')`);
			$('#company-logs').css('background-image', `url('../html/images/`+ jobType +`-logs.png')`);
			
			if (jobData.isArmoryLocked){
				$("#society-warehouse-title").html(`
					SOCIETY WAREHOUSE
					<span class="society-warehouse-status warehouse-locked"><i class="fad fa-lock-alt"></i> LOCKED</span>
				`)
			}else{
				$("#society-warehouse-title").html(`
					SOCIETY WAREHOUSE
					<span class="society-warehouse-status warehouse-unlocked"><i class="fad fa-unlock-alt"></i> UNLOCKED</span>
				`)
			}
			
			$('#wrap').fadeIn();
		}
		else if (event.data.action == 'hide') {
			HideEverything();
			$.post('http://esx_society/quit', JSON.stringify({}));
		}
		else if (event.data.action == 'manage_employees') {
			if (!event.data.isRewarding) {
				ManageEmployees(event.data.employees);
			}
			else {
				RewardEmployee(event.data.employees);
			}
			
			$('#wrap-settings').css('background-image', `url('../html/images/`+ jobType +`-background.png')`);
			$('#wrap-settings').fadeIn();
		}
		else if (event.data.action == 'hire') {
			ManageHireList(event.data.data);
			
			$('#wrap-invite').css('background-image', `url('../html/images/`+ jobType +`-background.png')`);
			$('#wrap-invite').fadeIn();
		}
		else if (event.data.action == 'myjobs') {
			SetupMyJobs(event.data.jobs)
			$('#wrap-myjobs').fadeIn();
		}
		else if (event.data.action == 'company_logs') {
			SetupLogs(event.data.logs)
			
			$('#wrap-logs').css('background-image', `url('../html/images/`+ jobType +`-background.png')`);
			$('#wrap-logs').fadeIn();
		}
		else if (event.data.action == 'company_privileges') {
			SetupPrivileges(event.data.privileges, event.data.config)
			
			$('#wrap-privileges').fadeIn();
		}
		else if (event.data.action == 'abilities') {
			SetupAbilities(event.data.abilities, event.data.config)
			
			$('#wrap-abilities').fadeIn();
		}
	});
	
	$('#btn-rank-up').click(function() {
		$.post('http://esx_society/rank_up', JSON.stringify({}));
	});
	
	$('#btn-change-boss').click(function() {
		HideEverything();
		$.post('http://esx_society/change_boss', JSON.stringify({}));
	});
	
	$('#btn-change-viceboss').click(function() {
		HideEverything();
		$.post('http://esx_society/change_viceboss', JSON.stringify({}));
	});
	
	$('#btn-expel-viceboss').click(function() {
		HideEverything();
		$.post('http://esx_society/expel_viceboss', JSON.stringify({}));
	});

	document.onkeyup = function(event) {
		if (event.key == 'Escape') {
			HideEverything();
			$.post('http://esx_society/quit', JSON.stringify({}));
		}
	};
});