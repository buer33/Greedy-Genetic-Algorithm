#include <iostream>
#include <vector>
#include <algorithm>
#include <numeric>

using namespace std;

struct Task {
    int id;
    double time;
    double resource;

    Task(int i, double t, double r) : id(i), time(t), resource(r) {}
};

struct VirtualMachine {
    int id;
    double time;
    double resource;
    vector<int> tasks;

    VirtualMachine(int i) : id(i), time(0), resource(0) {}

    // ������Դʹ��������������Դ�����ʱ������
    bool operator<(const VirtualMachine& vm) const {
        if (resource == vm.resource) {
            return time < vm.time;
        }
        return resource < vm.resource;
    }
};

// ��ʼ����������������
vector<Task> tasks = {
    {1, 20.1, 20.18}, {2, 20.7, 80.65}, {3, 16.5, 201.20}, {4, 24.4, 100.92}, 
    {5, 16.0, 10.08}, {6, 28.2, 40.40}, {7, 32.3, 60.68}, {8, 16.1, 30.20}, 
    {9, 20.6, 201.48}, {10, 23.2, 70.68}, {11, 21.6, 60.48}, {12, 20.0, 16.12}, 
    {13, 21.1, 100.76}, {14, 40.2, 20.32}, {15, 23.3, 141.16}, {16, 19.7, 100.84}, 
    {17, 21.6, 60.56}, {18, 20.4, 120.92}, {19, 24.3, 40.44}, {20, 12.5, 241.12}
};

vector<VirtualMachine> vms = { {1}, {2}, {3}, {4} };

// �������壺��Դ���ĵķ�Χ
const double Q_min = 50.0;
const double Q_max = 200.0;

// ������亯��
void assignTask(const Task& task, VirtualMachine& vm) {
    vm.time += task.time;
    vm.resource += task.resource;
    vm.tasks.push_back(task.id);
}

// ��ӡ����������������
void printResult() {
    for (const auto& vm : vms) {
        cout << "�����" << vm.id << ": " << vm.time << "s, ��Դ����: " << vm.resource << "\n������: ";
        for (int taskId : vm.tasks) {
            cout << taskId << " ";
        }
        cout << endl;
    }
}

// ��������߼�
void scheduleTasks() {
    // ��������ʱ���������
    sort(tasks.begin(), tasks.end(), [](const Task& t1, const Task& t2) {
        return t1.time > t2.time;
    });

    // ���������������Դ���ٵ������
    while (!tasks.empty()) {
        sort(vms.begin(), vms.end());  // �����������Դ��������
        assignTask(tasks.back(), vms.front());  // �������Դ���ٵ������
        tasks.pop_back();
    }
}

// ��Դ��������߼�
void balanceResources() {
    while (true) {
        auto minVmIt = min_element(vms.begin(), vms.end(), [](const VirtualMachine& vm1, const VirtualMachine& vm2) {
            return vm1.resource < vm2.resource;
        });

        auto maxVmIt = max_element(vms.begin(), vms.end(), [](const VirtualMachine& vm1, const VirtualMachine& vm2) {
            return vm1.resource < vm2.resource;
        });

        // ����Ƿ��Ѿ��ﵽ��Դƽ��
        if (maxVmIt->resource - minVmIt->resource <= Q_max - Q_min) break;

        // ����Դ�������������ת��������Դ��С�������
        if (!maxVmIt->tasks.empty()) {
            int taskId = maxVmIt->tasks.back();
            auto itTask = find_if(tasks.rbegin(), tasks.rend(), [&](const Task& task) {
                return task.id == taskId;
            });

            if (itTask != tasks.rend()) {
                assignTask(*itTask, *minVmIt);
                maxVmIt->time -= itTask->time;
                maxVmIt->resource -= itTask->resource;
                maxVmIt->tasks.pop_back();
                tasks.erase(next(itTask).base());
            } else {
                break;
            }
        } else {
            break;
        }
    }
}

int main() {
    scheduleTasks();       // �������
    balanceResources();    // ��Դ����
    printResult();         // ��ӡ���

    return 0;
}

