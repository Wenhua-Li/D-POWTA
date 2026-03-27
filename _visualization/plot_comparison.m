% D-POWTA 算法性能对比可视化
%
% 使用方式:
%   plot_comparison(results, instance_names, 'algorithms', {'KG-DREA','GA','LKEA','HA'})
%
% 输入:
%   results        - 各算法结果结构体数组
%   instance_names - 算例名称
%
% Author: KG-DREA
% Date: 2026-03-18

function plot_comparison(results, instance_names, varargin)
    p = inputParser;
    addOptional(p, 'algorithms', {'KG-DREA', 'GA', 'LKEA', 'HA'});
    addOptional(p, 'save_path', '', @ischar);
    parse(p, varargin{:});
    args = p.Results;

    n_instances = length(instance_names);
    n_algorithms = length(args.algorithms);

    fig = figure('Position', [100, 100, 1400, 800], 'Color', [1 1 1]);

    % 子图1: 性能柱状图
    subplot(2, 2, 1);
    performance_data = zeros(n_instances, n_algorithms);

    for i = 1:n_instances
        for j = 1:n_algorithms
            if ~isempty(results{i,j})
                performance_data(i,j) = results{i,j}.residual_threat(end);
            end
        end
    end

    bar(1:n_instances, performance_data);
    set(gca, 'XTickLabel', instance_names);
    xlabel('算例');
    ylabel('残余威胁 (越小越好)');
    title('各算法性能对比');
    legend(args.algorithms, 'Location', 'best');
    grid on;

    % 子图2: 收敛时间
    subplot(2, 2, 2);
    time_data = zeros(n_instances, n_algorithms);

    for i = 1:n_instances
        for j = 1:n_algorithms
            if ~isempty(results{i,j})
                time_data(i,j) = results{i,j}.total_time;
            end
        end
    end

    bar(1:n_instances, time_data);
    set(gca, 'XTickLabel', instance_names);
    xlabel('算例');
    ylabel('求解时间 (秒)');
    title('计算效率对比');
    legend(args.algorithms, 'Location', 'best');
    grid on;

    % 子图3: 箱线图
    subplot(2, 2, 3);
    all_fitness = {};
    for j = 1:n_algorithms
        fitness_list = [];
        for i = 1:n_instances
            if ~isempty(results{i,j})
                fitness_list = [fitness_list, results{i,j}.residual_threat];  %#ok<AGROW>
            end
        end
        all_fitness{j} = fitness_list;
    end

    boxplot(all_fitness, args.algorithms);
    ylabel('残余威胁');
    title('性能分布箱线图');
    grid on;

    % 子图4: 统计摘要表
    subplot(2, 2, 4);
    axis off;

    % 计算统计数据
    summary_data = cell(n_algorithms + 1, 4);
    summary_data(1,:) = {'算法', '平均性能', '标准差', '胜出次数'};

    for j = 1:n_algorithms
        fitness_list = [];
        wins = 0;
        for i = 1:n_instances
            if ~isempty(results{i,j})
                fitness_list = [fitness_list, results{i,j}.residual_threat(end)];
                if results{i,j}.residual_threat(end) <= results{i,1}.residual_threat(end)
                    wins = wins + 1;
                end
            end
        end
        summary_data{j+1, 1} = args.algorithms{j};
        summary_data{j+1, 2} = sprintf('%.4f', mean(fitness_list));
        summary_data{j+1, 3} = sprintf('%.4f', std(fitness_list));
        summary_data{j+1, 4} = num2str(wins);
    end

    table('Data', summary_data, 'Position', [0.1, 0.1, 0.8, 0.8]);
    title('统计摘要');

    sgtitle('算法性能综合对比', 'FontSize', 14, 'FontWeight', 'bold');

    if ~isempty(args.save_path)
        saveas(fig, args.save_path);
    end
end
