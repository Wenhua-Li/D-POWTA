% D-POWTA 测试集生成器
% 生成I1-I10共10个标准测试算例

function generate_test_suite
    clc; clear;

    fprintf('========================================\n');
    fprintf('   D-POWTA 测试集生成 (I1-I10)\n');
    fprintf('========================================\n\n');

    % 算例配置 (论文表1)
    configs = {
        struct('name','I1','n',24,'m',6,'L',6,'T_total',2,'phases',[13,11]), ...
        struct('name','I2','n',30,'m',6,'L',6,'T_total',3,'phases',[11,10,9]), ...
        struct('name','I3','n',50,'m',6,'L',6,'T_total',4,'phases',[14,13,12,11]), ...
        struct('name','I4','n',100,'m',6,'L',6,'T_total',5,'phases',[22,21,20,19,18]), ...
        struct('name','I5','n',100,'m',8,'L',6,'T_total',8,'phases',[14,13,13,13,12,12,12,11]), ...
        struct('name','I6','n',200,'m',8,'L',6,'T_total',5,'phases',[43,41,40,39,37]), ...
        struct('name','I7','n',200,'m',10,'L',6,'T_total',10,'phases',[22,21,21,20,20,20,19,19,19,19]), ...
        struct('name','I8','n',300,'m',10,'L',8,'T_total',6,'phases',[53,52,51,49,48,47]), ...
        struct('name','I9','n',500,'m',10,'L',8,'T_total',8,'phases',[67,65,64,63,63,62,61,55]), ...
        struct('name','I10','n',500,'m',10,'L',8,'T_total',10,'phases',[53,52,51,51,50,50,49,48,48,48])
    };

    % 创建instances目录
    if ~exist('instances', 'dir')
        mkdir('instances');
    end

    % 生成每个算例
    for idx = 1:length(configs)
        cfg = configs{idx};
        fprintf('[%d/%d] 生成算例 %s (n=%d, m=%d, L=%d, T=%d)\n', ...
            idx, length(cfg.name), cfg.name, cfg.n, cfg.m, cfg.L, cfg.T_total);

        instance = generate_instance(cfg);

        % 保存
        filename = sprintf('instances/%s.mat', cfg.name);
        save(filename, 'instance');
        fprintf('    保存至: %s\n', filename);
    end

    fprintf('\n========================================\n');
    fprintf('   测试集生成完成!\n');
    fprintf('========================================\n');
    fprintf('\n生成的算例文件:\n');
    for idx = 1:length(configs)
        fprintf('  - instances/%s.mat\n', configs{idx}.name);
    end
    fprintf('\n');
end

%% 生成单个算例
function instance = generate_instance(cfg)
    n = cfg.n; m = cfg.m; L = cfg.L; T_total = cfg.T_total;
    phase_targets = cfg.phases;

    % 防御区域边界
    DEF_X_MIN = 0; DEF_X_MAX = 50;
    DEF_Y_MIN = 50; DEF_Y_MAX = 150;

    % 武器位置 - 在防御区域内随机均匀分布
    weapon_x = DEF_X_MIN + rand(1, m) * (DEF_X_MAX - DEF_X_MIN);
    weapon_y = DEF_Y_MIN + rand(1, m) * (DEF_Y_MAX - DEF_Y_MIN);

    R_max = 150 + rand(1,m)*30;
    tau_react = 8 + rand(1,m)*4;
    v_weapon = 2.5 + rand(1,m)*0.5;
    priority = randi([2,3],1,m);
    ammo = 6 * ones(1,m);

    % 雷达位置 - 在防御区域内随机均匀分布
    radar_x = DEF_X_MIN + rand(1, L) * (DEF_X_MAX - DEF_X_MIN);
    radar_y = DEF_Y_MIN + rand(1, L) * (DEF_Y_MAX - DEF_Y_MIN);

    lambda = 5e-9 + rand(1,L)*2e-9;
    R_radar = 220 + rand(1,L)*30;
    p_th = 0.1;

    % 构建instance
    instance = struct();
    instance.name = cfg.name;
    instance.n = n; instance.m = m; instance.L = L; instance.T_total = T_total;
    instance.phase_targets = phase_targets;

    instance.weapon_x = weapon_x;
    instance.weapon_y = weapon_y;
    instance.R_max = R_max;
    instance.tau_react = tau_react;
    instance.v_weapon = v_weapon;
    instance.priority = priority;
    instance.ammo = ammo;
    instance.available = ammo;
    instance.alpha = ones(m,L);

    instance.radar_x = radar_x;
    instance.radar_y = radar_y;
    instance.lambda = lambda;
    instance.R_radar = R_radar;
    instance.p_th = p_th;
    instance.C_track = 10 * ones(1,L);
    instance.lambda0 = 1.0;
    instance.dt = 30;

    % 生成所有目标
    targets_all = generate_targets(n);

    % 生成各阶段数据
    instance.phases = cell(1,T_total);
    cumulative = 0;
    dt = 30;

    for t = 1:T_total
        n_t = phase_targets(t);
        current_targets = targets_all(cumulative+1:cumulative+n_t);

        % 更新位置
        for j = 1:n_t
            heading_rad = current_targets(j).heading * pi / 180;
            current_targets(j).position_x = current_targets(j).position_x - (t-1)*dt*current_targets(j).speed*cos(heading_rad);
            current_targets(j).position_y = current_targets(j).position_y - (t-1)*dt*current_targets(j).speed*sin(heading_rad);
        end

        % 计算矩阵
        [P_ij, eta_j, d_ij] = compute_matrices(current_targets, weapon_x, weapon_y, R_max, radar_x, radar_y, lambda, R_radar, p_th);

        phase_data = struct();
        phase_data.phase = t;
        phase_data.n_t = n_t;
        phase_data.targets = current_targets;
        phase_data.P_ij = P_ij;
        phase_data.eta_j = eta_j;
        phase_data.d_ij = d_ij;
        phase_data.W_jt = zeros(1,n_t);
        phase_data.U_jt = zeros(1,n_t);
        phase_data.P_min_jt = zeros(1,n_t);
        for j = 1:n_t
            phase_data.W_jt(j) = current_targets(j).W;
            phase_data.U_jt(j) = current_targets(j).U;
            phase_data.P_min_jt(j) = current_targets(j).P_min;
        end
        phase_data.available = ammo;

        instance.phases{t} = phase_data;
        cumulative = cumulative + n_t;
    end
end

%% 生成目标
function targets = generate_targets(n)
    targets = struct('id',{},'position_x',{},'position_y',{},'speed',{},'heading',{},'threat',{},'RCS',{},'W',{},'U',{},'P_min',{},'category',{});

    % 6:3:1分布
    n_conv = round(n*0.6);
    n_low = round(n*0.3);
    n_stealth = n - n_conv - n_low;

    categories = [repmat({'conventional'},1,n_conv), repmat({'low_observable'},1,n_low), repmat({'stealth'},1,n_stealth)];
    categories = categories(randperm(n));

    for j = 1:n
        targets(j).id = j;
        targets(j).position_x = 100 + rand()*80;
        targets(j).position_y = rand()*200;
        targets(j).speed = 0.3 + rand()*0.4;

        heading = atan2(75-targets(j).position_y, 25-targets(j).position_x)*180/pi;
        targets(j).heading = heading + (rand()-0.5)*40;

        x_norm = (targets(j).position_x-100)/80;
        targets(j).threat = max(0.3, min(1.0, (1-x_norm)+rand()*0.3));

        cat = categories{j};
        if strcmp(cat,'conventional')
            targets(j).RCS = 10^(rand()*0.699);
        elseif strcmp(cat,'low_observable')
            targets(j).RCS = 10^(rand()-1);
        else
            targets(j).RCS = 10^(rand()-2);
        end
        targets(j).category = cat;

        targets(j).W = 60 + rand()*30;
        targets(j).U = randi([1,3]);
        targets(j).P_min = 0.3 + rand()*0.2;
    end
end

%% 计算矩阵
function [P_ij, eta_j, d_ij] = compute_matrices(targets, weapon_x, weapon_y, R_max, radar_x, radar_y, lambda, R_radar, p_th)
    n = length(targets); m = length(weapon_x); L = length(radar_x);
    P_ij = zeros(m,n); d_ij = zeros(m,n);

    for i = 1:m
        for j = 1:n
            d_ij(i,j) = sqrt((weapon_x(i)-targets(j).position_x)^2 + (weapon_y(i)-targets(j).position_y)^2);
            if d_ij(i,j) <= R_max(i)
                range_factor = 1 - d_ij(i,j)/R_max(i);
                rcs_factor = min(1, targets(j).RCS/1.0);
                P_ij(i,j) = min(0.99, 0.7*range_factor*rcs_factor+0.25);
            else
                P_ij(i,j) = 0;
            end
        end
    end

    p_kj = zeros(L,n);
    for k = 1:L
        for j = 1:n
            d_kj = sqrt((radar_x(k)-targets(j).position_x)^2 + (radar_y(k)-targets(j).position_y)^2);
            if d_kj <= R_radar(k)
                p_kj(k,j) = max(0.05, exp(-lambda(k)*d_kj^4/targets(j).RCS));
            end
        end
    end

    eta_j = zeros(1,n);
    for j = 1:n
        valid = find(p_kj(:,j) >= p_th);
        if isempty(valid), valid = find(p_kj(:,j) > 0); end
        if isempty(valid)
            eta_j(j) = 0;
        else
            prod_term = 1;
            for k = valid'
                prod_term = prod_term * (1 - p_kj(k,j));
            end
            eta_j(j) = max(0.1, 1 - prod_term);
        end
    end
end
