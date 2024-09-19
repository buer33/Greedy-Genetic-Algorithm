clear all;
close all;
clc;

 %四个容器对资源CPU、内存、IO的需求：CPU/个，内存/GB，IO/Mbps
%D = [1.0 2.00 1000 ; 0.6 1.30 500 ; 0.9	2.00 700];
%D_tmin = [16.5 21.1 23.3]; %四个容器完成的最短时间
%D_tmax = [24.5 31.5 34.7];   %四个容器完成的最长时间

 %四个容器对资源CPU、内存、IO的需求：CPU/个，内存/GB，IO/Mbps
%D = [0.5 1.20 300 ; 0.7 1.00 350 ; 0.4 0.80	300 ; 1.0 1.8 1200];
%D_tmin = [32.3 23.2 21.6 12.5]; %四个容器完成的最短时间
%D_tmax = [48.25 24.05 42.15 18.5];  %四个容器完成的最长时间

% 容器对资源CPU、内存、IO的需求：CPU/个，内存/GB，IO/Mbps
%D = [0.2 0.25 100 ; 0.6 1.02 400 ; 0.8 1.50 500 ; 0.2 0.30 150 ; 
%     0.1 0.20 80 ; 0.6 0.8 300 ; 0.8 1.5 600];
%D_tmin = [20.1 20.7 24.4 16.1 20.0 21.6 20.4];  % 最短完成时间
%D_tmax = [30.1 30.9 36.4 24.1 30.0 32.3 30.4];  % 最长完成时间

%四个容器对资源CPU、内存、IO的需求：CPU/个，内存/GB，IO/Mbps
D = [0.1 0.10 50 ; 0.3 0.70	200 ; 1.2 2.50 1000 ; 0.3 0.50 100 ; 
        0.9 1.2 500 ; 0.5 0.6 200 ];

D_tmin = [16.0 28.2 20.6 40.2 19.7 24.3]; %四个容器完成的最短时间
D_tmax = [24.0 42.2 30.6 60.2 29.3 36.3]; %四个容器完成的最长时间

V = [2 4 2000];  % 虚拟机上各资源的总量

%min_col = [0.42 , 0.9 , 550]; % 每一列的最小值
%max_col = [0.7 , 1.4 , 700]; % 每一列的最大值

%min_col = [0.35 , 0.56 , 210]; % 每一列的最小值
%max_col = [0.7 , 1.26 , 840]; % 每一列的最大值

%min_col = [0.07 , 0.14 , 56];  % 每种资源的最小值
%max_col = [0.56 , 1.05 , 420]; % 每种资源的最大值

min_col = [0.03 , 0.03 , 30]; % 每一列的最小值
max_col = [0.84 , 1.75 , 700]; % 每一列的最大值

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