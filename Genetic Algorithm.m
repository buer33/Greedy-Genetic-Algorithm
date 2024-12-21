clear all;
close all;
clc;

D = [];

D_tmin = []; 
D_tmax = []; 

V = [];  % Total amount of resources on each VM

min_col = []; % Minimum value for each column
max_col = []; % Maximum value for each column

[row, col] = size(D);  % Number of rows and columns
N = row * col;         % Number of resource requests

% Genetic Algorithm parameters
NP = 500;    % Population size
G = 200;     % Maximum number of generations
% Array to record the best fitness values
best_fitness_history = [];

f = initialize_population(NP, row, col, min_col, max_col, V);

% Core genetic algorithm loop
gen = 0;
while gen < G
    fitness = calculate_fitness(f, NP, row, col, D, D_tmin, D_tmax, N);
    
    best_fitness = min(fitness);
    best_fitness_history = [best_fitness_history, best_fitness];
    
    f = genetic_operations(f, fitness, NP, row, col, N);
    
    gen = gen + 1;
end


% Output final results
disp('Optimal allocation:');
disp(f(1,:));
disp(['Number of iterations: ', num2str(gen)]);

% Plot the curve of fitness function values against the number of iterations
figure;
plot(1:length(best_fitness_history), best_fitness_history, '-o');
title('Change in Fitness Function Value over Iterations');
xlabel('Iterations');
ylabel('Fitness Value');
grid on;

% ======================= Function Definitions =======================
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

% Helper function: Generate random numbers that conform to constraints
function values = rand_constrained(row, min_val, max_val, total)
    values = min_val + (max_val - min_val) * rand(row, 1);
    scaling_factor = total / sum(values);
    values = values * scaling_factor;
end

% Fitness calculation function
function fitness = calculate_fitness(population, NP, row, col, D, D_tmin, D_tmax, N)
    fitness = zeros(NP, 1);
    for i = 1:NP
        k = 1;
        total_time = zeros(1, row);
        for j = 1:row
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

% Helper function: Resource utilization calculation
function u = used(D, f)
    x = 1 - (D - f) ./ D;
    x(f >= D) = 1;
    u = mean(x);
    %u = sum(D ./ f) / length(D);
end

% Genetic operations: Selection, crossover, mutation
function new_population = genetic_operations(population, fitness, NP, row, col, N)
    new_population = zeros(NP, N);
    
    % Selection operation: Tournament selection (only retains part of the population)
    num = 0;
    for i = 1 : NP
        index = roulette_wheel_selection(fitness); 
        %disp(index);
        num = num + 1;
        new_population(num , :) = population(index , :); 
    end
    new_population = new_population(1 : num , :);
    
    for i = 1:NP
        numper = randperm(num);
        parent1_idx = new_population(numper(1) , :);
        parent2_idx = new_population(numper(2) , :);
        
        % Crossover
        crossover_point = randi([1 N]);
        if mod(crossover_point , 3) == 1
            index_1 = 1 : 3 : N;
            crossover_point_1 = randsample(index_1 , 1);
            temp1 = [parent1_idx(1 : crossover_point - 1) parent2_idx(crossover_point_1) parent1_idx(crossover_point + 1:end)];
            if sum(temp1(index_1)) < 2  && sum(temp1(index_1)) > 1.4
                parent1_idx = temp1;
            end
        end
        if mod(crossover_point , 3) == 2
            index_2 = 2 : 3 : N;
            crossover_point_2 = randsample(index_2 , 1);
            temp1 = [parent1_idx(1 : crossover_point - 1) parent2_idx(crossover_point_2) parent1_idx(crossover_point + 1:end)];
            if sum(temp1(index_2)) < 4  && sum(temp1(index_2)) > 2.7
                parent1_idx = temp1;
            end
        end
        if mod(crossover_point , 3) == 0
            index_3 = 3 : 3 : N;
            crossover_point_3 = randsample(index_3 , 1);
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
        
        % Mutation
        if rand() < 0.1
            parent3_idx = new_population(numper(3) , :);
            mutation_point = randi([1 N]);
            if mod(mutation_point , 3) == 1
                index = 1 : 3 : N;
                change = (rand - 0.5) * 0.2;
                if parent3_idx(mutation_point) + change > 0.07 && sum(parent3_idx(index)) < 2 && sum(parent3_idx(index)) > 1.4
                    parent3_idx(mutation_point) = parent3_idx(mutation_point) + change;
                end
            end
            if mod(mutation_point , 3) == 2
                index = 2 : 3 : N;
                change = (rand - 0.5) * 0.2;
                if parent3_idx(mutation_point) + change > 0.07 && sum(parent3_idx(index)) < 4 && sum(parent3_idx(index)) > 2.7
                    parent3_idx(mutation_point) = parent3_idx(mutation_point) + change;
                end
            end
            if mod(mutation_point , 3) == 0
                index = 3 : 3 : N;
                change = (rand - 0.5) * 120;
                if parent3_idx(mutation_point) + change > 30 && sum(parent3_idx(index)) < 2000 && sum(parent3_idx(index)) > 1400
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
    % Roulette wheel selection
    r = rand();
    fitness = 1 ./ fitness; 
    fitness = fitness / sum(fitness);
    cumulative_fitness = cumsum(fitness);
    index = find(cumulative_fitness >= r, 1);
end
