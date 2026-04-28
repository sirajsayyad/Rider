import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature 7: Corporate Accounts

class CorporateAccount {
  final String id;
  final String companyName;
  final String gstNumber;
  final String adminEmail;
  final double monthlyBudget;
  final double usedBudget;
  final List<CorporateEmployee> employees;
  final List<CorporateInvoice> invoices;
  final bool isActive;
  final DateTime createdAt;

  const CorporateAccount({
    required this.id,
    required this.companyName,
    required this.gstNumber,
    required this.adminEmail,
    required this.monthlyBudget,
    this.usedBudget = 0,
    this.employees = const [],
    this.invoices = const [],
    this.isActive = true,
    required this.createdAt,
  });

  double get remainingBudget => monthlyBudget - usedBudget;
  double get budgetUsagePercent => monthlyBudget > 0 ? usedBudget / monthlyBudget : 0;

  CorporateAccount copyWith({
    double? usedBudget,
    List<CorporateEmployee>? employees,
    List<CorporateInvoice>? invoices,
    double? monthlyBudget,
  }) {
    return CorporateAccount(
      id: id,
      companyName: companyName,
      gstNumber: gstNumber,
      adminEmail: adminEmail,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      usedBudget: usedBudget ?? this.usedBudget,
      employees: employees ?? this.employees,
      invoices: invoices ?? this.invoices,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}

class CorporateEmployee {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double monthlySpent;
  final int totalRides;
  final bool isLinked;

  const CorporateEmployee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.monthlySpent = 0,
    this.totalRides = 0,
    this.isLinked = true,
  });
}

class CorporateInvoice {
  final String id;
  final String month;
  final double totalAmount;
  final int totalRides;
  final int totalEmployees;
  final bool isPaid;
  final DateTime generatedAt;

  const CorporateInvoice({
    required this.id,
    required this.month,
    required this.totalAmount,
    required this.totalRides,
    required this.totalEmployees,
    this.isPaid = false,
    required this.generatedAt,
  });
}

class CorporateState {
  final CorporateAccount? account;
  final bool isLoading;
  final String? error;

  const CorporateState({this.account, this.isLoading = false, this.error});

  CorporateState copyWith({
    CorporateAccount? account,
    bool? isLoading,
    String? error,
  }) {
    return CorporateState(
      account: account ?? this.account,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CorporateController extends StateNotifier<CorporateState> {
  CorporateController() : super(const CorporateState()) {
    _loadDemoData();
  }

  final _random = Random();

  void _loadDemoData() {
    state = state.copyWith(
      account: CorporateAccount(
        id: 'corp_001',
        companyName: 'TechServe Solutions Pvt. Ltd.',
        gstNumber: '27AADCT1234F1Z5',
        adminEmail: 'admin@techserve.in',
        monthlyBudget: 50000,
        usedBudget: 32450,
        employees: [
          const CorporateEmployee(
            id: 'emp_1', name: 'Rahul Mehta', email: 'rahul@techserve.in',
            phone: '+91 98XXXX1234', monthlySpent: 4500, totalRides: 22,
          ),
          const CorporateEmployee(
            id: 'emp_2', name: 'Sneha Iyer', email: 'sneha@techserve.in',
            phone: '+91 87XXXX5678', monthlySpent: 3800, totalRides: 18,
          ),
          const CorporateEmployee(
            id: 'emp_3', name: 'Vikram Joshi', email: 'vikram@techserve.in',
            phone: '+91 99XXXX9876', monthlySpent: 5200, totalRides: 25,
          ),
        ],
        invoices: [
          CorporateInvoice(
            id: 'inv_1', month: 'March 2026', totalAmount: 45600,
            totalRides: 86, totalEmployees: 8, isPaid: true,
            generatedAt: DateTime(2026, 4, 1),
          ),
          CorporateInvoice(
            id: 'inv_2', month: 'February 2026', totalAmount: 38900,
            totalRides: 72, totalEmployees: 7, isPaid: true,
            generatedAt: DateTime(2026, 3, 1),
          ),
        ],
        createdAt: DateTime(2026, 1, 15),
      ),
    );
  }

  void addEmployee(String name, String email, String phone) {
    final account = state.account;
    if (account == null) return;
    final employee = CorporateEmployee(
      id: 'emp_${_random.nextInt(1000)}',
      name: name,
      email: email,
      phone: phone,
    );
    state = state.copyWith(
      account: account.copyWith(
        employees: [...account.employees, employee],
      ),
    );
  }

  void removeEmployee(String employeeId) {
    final account = state.account;
    if (account == null) return;
    state = state.copyWith(
      account: account.copyWith(
        employees: account.employees.where((e) => e.id != employeeId).toList(),
      ),
    );
  }

  void updateBudget(double newBudget) {
    final account = state.account;
    if (account == null) return;
    state = state.copyWith(
      account: account.copyWith(monthlyBudget: newBudget),
    );
  }
}

final corporateControllerProvider =
    StateNotifierProvider<CorporateController, CorporateState>((ref) {
  return CorporateController();
});
