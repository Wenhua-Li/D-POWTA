% D-POWTA 算例加载工具
%
% 使用方式:
%   instance = load_instance('I1.mat')
%   instance = load_instance('I1.mat', 'instances/')
%
% 输入:
%   filename     - 算例文件名
%   instance_dir - 算例目录 (可选，默认 'instances/')
%
% 输出:
%   instance - 算例数据结构体
%
% Author: KG-DREA
% Date: 2026-03-18

function instance = load_instance(filename, instance_dir)
    if nargin < 2 || isempty(instance_dir)
        instance_dir = 'instances/';
    end

    filepath = fullfile(instance_dir, filename);

    if ~exist(filepath, 'file')
        error('算例文件不存在: %s', filepath);
    end

    data = load(filepath);

    if isfield(data, 'instance')
        instance = data.instance;
    else
        instance = data;
    end

    fprintf('算例加载成功: %s\n', filename);
    fprintf('  武器数: %d, 雷达数: %d, 总目标数: %d, 阶段数: %d\n', ...
        instance.m, instance.L, instance.n, instance.T_total);
end
