clear all;
close all;
clc;

D = [];

D_tmin = []; 
D_tmax = []; 

V = [];  % 虚拟机上各资源的总量

min_col = []; % 每一列的最小值
max_col = []; % 每一列的最大值

[row, col] = size(D);  % 行和列
N = row * col;         % 资源请求数

% 遗传算法参数
NP = 500;    % 种群规模
G = 200;     % 最大遗传代数
% 用于记录最优适应度值的数组
best_fitness_history = [];

% 1. 初始化种群
f = initialize_population(NP, row, col, min_col, max_col, V);

% 遗传算法核心流程
gen = 0;
while gen < G
    % 2. 计算适应度
    fitness = calculate_fitness(f, NP, row, col, D, D_tmin, D_tmax, N);
    
    % 记录每一代的最优适应度
    best_fitness = min(fitness);
    best_fitness_history = [best_fitness_history, best_fitness];
    
    % 3. 选择、交叉、变异生成新种群
    f = genetic_operations(f, fitness, NP, row, col, N);
    
    % 更新代数
    gen = gen + 1;
end


% 输出最终结果
disp('最优分配方案:');
disp(f(1,:));
disp(['迭代次数: ', num2str(gen)]);

% 绘制适应度函数值随迭代次数的曲线图
figure;
plot(1:length(best_fitness_history), best_fitness_history, '-o');
title('适应度函数值随迭代次数的变化');
xlabel('迭代次数');
ylabel('适应度值');
grid on;

% ======================= 函数定义 =======================
function population = initialize_population(NP, row, col, min_col, max_col, V)
    population = zeros(NP, row * col);
    for i = 1:NP
        temp = zeros(row, col);
        for j = 1:col
            temp(:,j) = rand_constrained(row, min_col(j), max_col(j), V(j));
        end
        population(i,:) = reshape(transpose(temp), [1, row * col]);
    end
end

% 辅助函数：生成符合约束的随机数
function values = rand_constrained(row, min_val, max_val, total)
    values = min_val + (max_val - min_val) * rand(row, 1);
    scaling_factor = total / sum(values);
    values = values * scaling_factor;
end

% 2. 适应度计算函数
function fitness = calculate_fitness(population, NP, row, col, D, D_tmin, D_tmax, N)
    fitness = zeros(NP, 1);
    for i = 1:NP
        k = 1;
        total_time = zeros(1, row);
        for j = 1:row
            % 计算每个容器的资源利用率和完成时间
            x = D(j, :);
            xref = population(i, k:k+col-1);
            utilization = used(x, xref);
            total_time(j) = D_tmin(j) - (D_tmin(j) - D_tmax(j)) * (1 - utilization);
            k = k + col;
        end
        avg_time = mean(total_time);
        fitness(i) = sum((total_time - avg_time).^2) / row;
        %disp(fitness);
    end
end

% 辅助函数：资源利用率计算
function u = used(D, f)
    x = 1 - (D - f) ./ D;
    x(f >= D) = 1;
    u = mean(x);
    %u = sum(D ./ f) / length(D);
end

% 3. 遗传操作：选择、交叉、变异
function new_population = genetic_operations(population, fitness, NP, row, col, N)
    new_population = zeros(NP, N);
    
    %选择操作:竞赛选择算法(只能保留部分的种群)
    num = 0;%记录选择后的种群个数
    for i = 1 : NP
        index = roulette_wheel_selection(fitness); % 按照适应度值的概率选择一个个体
        %disp(index);
        num = num + 1;
        new_population(num , :) = population(index , :); % 将选择的个体复制到新种群矩阵中
    end
    new_population = new_population(1 : num , :);
    
    for i = 1:NP
        numper = randperm(num);
        parent1_idx = new_population(numper(1) , :);
        parent2_idx = new_population(numper(2) , :);
        
        % 交叉
        crossover_point = randi([1 N]);
        if mod(crossover_point , 3) == 1%如果这个整数是容器的第一个资源参数，就和另一条染色体的该资源参数进行随机交换
            index_1 = 1 : 3 : N;%另一条染色体的可交换的资源参数的下标
            crossover_point_1 = randsample(index_1 , 1);%随机挑选一个可交换的下标
            temp1 = [parent1_idx(1 : crossover_point - 1) parent2_idx(crossover_point_1) parent1_idx(crossover_point + 1:end)];
            if sum(temp1(index_1)) < 2  && sum(temp1(index_1)) > 1.4
                parent1_idx = temp1;
            end
        end
        if mod(crossover_point , 3) == 2%如果这个整数是容器的第二个资源参数，就和另一条染色体的该资源参数进行随机交换
            index_2 = 2 : 3 : N;%另一条染色体的可交换的资源参数的下标
            crossover_point_2 = randsample(index_2 , 1);%随机挑选一个可交换的下标
            temp1 = [parent1_idx(1 : crossover_point - 1) parent2_idx(crossover_point_2) parent1_idx(crossover_point + 1:end)];
            if sum(temp1(index_2)) < 4  && sum(temp1(index_2)) > 2.7
                parent1_idx = temp1;
            end
        end
        if mod(crossover_point , 3) == 0%如果这个整数是容器的第二个资源参数，就和另一条染色体的该资源参数进行随机交换
            index_3 = 3 : 3 : N;%另一条染色体的可交换的资源参数的下标
            crossover_point_3 = randsample(index_3 , 1);%随机挑选一个可交换的下标
            temp1 = [parent1_idx(1 : crossover_point - 1) parent2_idx(crossover_point_3) parent1_idx(crossover_point + 1:end)];
            if sum(temp1(index_3)) < 2000  && sum(temp1(index_3)) > 1400
                parent1_idx = temp1;
            end
        end
        new_population = [parent1_idx ; new_population];
        [row1, col1] = size(new_population);
        if row1 > NP
            new_population = new_population(1 : NP , :);
        end
        
        % 变异
        if rand() < 0.1
            parent3_idx = new_population(numper(3) , :);
            mutation_point = randi([1 N]);
            if mod(mutation_point , 3) == 1%变异的判断下标和交换相似，因为不同的资源参数需要赋值不同范围的整数
                index = 1 : 3 : N;
                change = (rand - 0.5) * 0.2;%得到一个-0.1到0.1之间的随机数
                if parent3_idx(mutation_point) + change > 0.07 && sum(parent3_idx(index)) < 2 && sum(parent3_idx(index)) > 1.4%如果变异符合要求，即不能小于等于0且变异后的该资源参数总值不能大于虚拟机上的总量
                    parent3_idx(mutation_point) = parent3_idx(mutation_point) + change;
                end
            end
            if mod(mutation_point , 3) == 2%变异的判断下标和交换相似，因为不同的资源参数需要赋值不同范围的整数
                index = 2 : 3 : N;
                change = (rand - 0.5) * 0.2;%得到一个-0.1到0.1之间的随机数
                if parent3_idx(mutation_point) + change > 0.07 && sum(parent3_idx(index)) < 4 && sum(parent3_idx(index)) > 2.7%如果变异符合要求，即不能小于等于0且变异后的该资源参数总值不能大于虚拟机上的总量
                    parent3_idx(mutation_point) = parent3_idx(mutation_point) + change;
                end
            end
            if mod(mutation_point , 3) == 0%变异的判断下标和交换相似，因为不同的资源参数需要赋值不同范围的整数
                index = 3 : 3 : N;
                change = (rand - 0.5) * 120;%得到一个-0.1到0.1之间的随机数
                if parent3_idx(mutation_point) + change > 30 && sum(parent3_idx(index)) < 2000 && sum(parent3_idx(index)) > 1400%如果变异符合要求，即不能小于等于0且变异后的该资源参数总值不能大于虚拟机上的总量
                    parent3_idx(mutation_point) = parent3_idx(mutation_point) + change;
                end
            end
            new_population = [parent3_idx ; new_population];
            [row2, col2] = size(new_population);
            if row2 > NP
                new_population = new_population(1 : NP , :);
            end
        end
    end
end

function index = roulette_wheel_selection(fitness)
    % 轮盘赌选择
    r = rand();
    fitness = 1 ./ fitness;  % 反转适应度以进行选择
    fitness = fitness / sum(fitness);
    cumulative_fitness = cumsum(fitness);
    index = find(cumulative_fitness >= r, 1);
end
