import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'models/expense_transaction.dart';
import 'services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const ExpenseApp());
}

const List<String> categories = [
  'Food',
  'Shopping',
  'Transport',
  'Bills',
  'Health',
  'Education',
  'Entertainment',
  'Salary',
  'Business',
  'Other',
];

const Color primaryBlue = Color(0xFF168BDF);
const Color paleBlue = Color(0xFFF2F8FE);

final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);

void notifyDataChanged() => dataRevision.value++;

String money(num value) => 'PKR ${value.toStringAsFixed(2)}';

String dateText(DateTime value) => DateFormat('dd MMM yyyy').format(value);

Widget transactionData(
  Widget Function(BuildContext, AsyncSnapshot<List<ExpenseTransaction>>)
      builder,
) {
  return ValueListenableBuilder<int>(
    valueListenable: dataRevision,
    builder: (context, revision, child) =>
        FutureBuilder<List<ExpenseTransaction>>(
      key: ValueKey<int>(revision),
      future: DatabaseService.instance.all(),
      builder: builder,
    ),
  );
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        scaffoldBackgroundColor: paleBlue,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AppShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.account_balance_wallet, size: 76, color: primaryBlue),
              SizedBox(height: 12),
              Text(
                'Expense Tracker',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              Text('Track • Manage • Save'),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedTab = 0;
  final List<Widget> pages = const [
    DashboardScreen(),
    TransactionsScreen(),
    AnalyticsScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];
  final List<String> titles = const [
    'Home Dashboard',
    'Transactions',
    'Analytics',
    'Calendar',
    'Settings',
  ];

  Future<void> openAddTransaction() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TransactionFormScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> openEditTransaction() async {
    final items = await DatabaseService.instance.all();
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no transactions to edit yet.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ChooseTransactionToEditScreen(),
      ),
    );
  }

  void openPage(Widget page) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  ListTile drawerItem(String title, IconData icon, VoidCallback action) =>
      ListTile(leading: Icon(icon), title: Text(title), onTap: action);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedTab]),
        actions: [
          IconButton(
            onPressed: openAddTransaction,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: primaryBlue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 40,
                  ),
                  Text(
                    'Expense Tracker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Offline finance manager',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            drawerItem('Home Dashboard', Icons.home, () {
              Navigator.pop(context);
              setState(() => selectedTab = 0);
            }),
            drawerItem('Add Transaction', Icons.add, () {
              Navigator.pop(context);
              openAddTransaction();
            }),
            drawerItem('Transactions List', Icons.receipt_long, () {
              Navigator.pop(context);
              setState(() => selectedTab = 1);
            }),
            drawerItem(
              'Select Category',
              Icons.category,
              () => openPage(const CategoryScreen()),
            ),
            drawerItem('Analytics', Icons.analytics, () {
              Navigator.pop(context);
              setState(() => selectedTab = 2);
            }),
            drawerItem('Settings / Profile', Icons.settings, () {
              Navigator.pop(context);
              setState(() => selectedTab = 4);
            }),
            drawerItem('Edit Transaction', Icons.edit, () {
              Navigator.pop(context);
              openEditTransaction();
            }),
            drawerItem(
              'Categories Management',
              Icons.tune,
              () => openPage(const CategoryManagementScreen()),
            ),
            drawerItem('Calendar View', Icons.calendar_month, () {
              Navigator.pop(context);
              setState(() => selectedTab = 3);
            }),
            drawerItem(
              'Reports and Search',
              Icons.search,
              () => openPage(const SearchReportsScreen()),
            ),
            drawerItem(
              'Financial Reports',
              Icons.pie_chart,
              () => openPage(const FinancialReportsScreen()),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: selectedTab, children: pages),
      floatingActionButton: selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: openAddTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (value) => setState(() => selectedTab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'History',
          ),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Stats'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => transactionData((context, snapshot) {
        if (snapshot.hasError)
          return ErrorMessage(
            message: 'Could not load transactions: ${snapshot.error}',
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingView();
        final items = snapshot.data ?? <ExpenseTransaction>[];
        final income = items
            .where((x) => x.type == 'Income')
            .fold<double>(0, (sum, x) => sum + x.amount);
        final expenses = items
            .where((x) => x.type == 'Expense')
            .fold<double>(0, (sum, x) => sum + x.amount);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Good day!', style: TextStyle(color: Colors.grey)),
            const Text(
              'Your money at a glance',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    money(income - expenses),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Income: ${money(income)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Expenses: ${money(expenses)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Total Income',
                    amount: income,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    title: 'Total Expenses',
                    amount: expenses,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Recent Transactions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (items.isEmpty)
              const EmptyState(
                message: 'No transactions yet. Add your first transaction.',
              )
            else
              ...items.take(5).map((item) => TransactionTile(item: item)),
          ],
        );
      });
}

class MetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  const MetricCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.account_balance_wallet, color: color),
              Text(title),
              Text(
                money(amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
}

class TransactionFormScreen extends StatefulWidget {
  final ExpenseTransaction? item;
  const TransactionFormScreen({super.key, this.item});
  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController amountController;
  late final TextEditingController noteController;
  late String type;
  late String category;
  late DateTime date;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.item?.title ?? '');
    amountController = TextEditingController(
      text: widget.item?.amount.toString() ?? '',
    );
    noteController = TextEditingController(text: widget.item?.note ?? '');
    type = widget.item?.type ?? 'Expense';
    category = categories.contains(widget.item?.category)
        ? widget.item!.category
        : 'Food';
    date = widget.item?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !(formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      final transaction = ExpenseTransaction(
        id: widget.item?.id,
        title: titleController.text.trim(),
        amount: double.parse(amountController.text.trim()),
        type: type,
        category: category,
        date: date,
        note: noteController.text.trim(),
      );
      if (widget.item == null) {
        await DatabaseService.instance.add(transaction);
      } else {
        await DatabaseService.instance.edit(transaction);
      }
      notifyDataChanged();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save transaction: $error')),
        );
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
              widget.item == null ? 'Add Transaction' : 'Edit Transaction'),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Expense',
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: 'Income',
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: <String>{type},
                onSelectionChanged: (selection) =>
                    setState(() => type = selection.first),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (PKR)',
                  prefixIcon: Icon(Icons.currency_exchange),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || !parsed.isFinite || parsed <= 0)
                    return 'Enter an amount greater than zero';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => category = value);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month, color: primaryBlue),
                title: const Text('Date'),
                subtitle: Text(dateText(date)),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selected != null) setState(() => date = selected);
                },
              ),
              TextFormField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: saving ? null : save,
                child: Text(
                  saving
                      ? 'Saving...'
                      : (widget.item == null
                          ? 'Save Transaction'
                          : 'Update Transaction'),
                ),
              ),
            ],
          ),
        ),
      );
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});
  @override
  Widget build(BuildContext context) => transactionData((context, snapshot) {
        if (snapshot.hasError)
          return ErrorMessage(
            message: 'Could not load transactions: ${snapshot.error}',
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingView();
        final items = snapshot.data ?? <ExpenseTransaction>[];
        if (items.isEmpty)
          return const EmptyState(
            message: 'Your transaction history will appear here.',
          );
        return ListView(
          padding: const EdgeInsets.all(8),
          children: items.map((item) => TransactionTile(item: item)).toList(),
        );
      });
}

class TransactionTile extends StatelessWidget {
  final ExpenseTransaction item;
  const TransactionTile({super.key, required this.item});

  Future<void> handleAction(BuildContext context, String action) async {
    if (action == 'edit') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TransactionFormScreen(item: item),
        ),
      );
      notifyDataChanged();
    } else if (action == 'delete' && item.id != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete transaction?'),
          content: Text('Delete "${item.title}" permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await DatabaseService.instance.remove(item.id!);
        notifyDataChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: item.type == 'Income'
                ? Colors.green.shade50
                : Colors.red.shade50,
            child: Icon(
              item.type == 'Income' ? Icons.south_west : Icons.north_east,
              color: item.type == 'Income' ? Colors.green : Colors.red,
            ),
          ),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${item.category} • ${dateText(item.date)}'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => handleAction(context, value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      );
}

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Select Category')),
        body: ListView(
          children: categories
              .map(
                (category) => ListTile(
                  leading: const Icon(Icons.label_outline, color: primaryBlue),
                  title: Text(category),
                  onTap: () => Navigator.of(context).pop(category),
                ),
              )
              .toList(),
        ),
      );
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context) => transactionData((context, snapshot) {
        if (snapshot.hasError)
          return ErrorMessage(
            message: 'Could not load analytics: ${snapshot.error}',
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingView();
        final expenses = (snapshot.data ?? <ExpenseTransaction>[]).where(
          (x) => x.type == 'Expense',
        );
        final totals = <String, double>{};
        for (final item in expenses) {
          totals[item.category] = (totals[item.category] ?? 0) + item.amount;
        }
        final colors = <Color>[
          Colors.lightBlue,
          Colors.orange,
          Colors.blue,
          Colors.purple,
          Colors.red,
          Colors.green,
          Colors.teal,
          Colors.amber,
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Spending Analytics',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (totals.isEmpty)
              const EmptyState(message: 'Add expenses to see analytics.')
            else ...[
              SizedBox(
                height: 260,
                child: PieChart(
                  PieChartData(
                    sections: totals.entries
                        .toList()
                        .asMap()
                        .entries
                        .map(
                          (entry) => PieChartSectionData(
                            value: entry.value.value,
                            title:
                                '${entry.value.key}\n${entry.value.value.toStringAsFixed(0)}',
                            color: colors[entry.key % colors.length],
                            radius: 82,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              ...totals.entries.map(
                (entry) => ListTile(
                  title: Text(entry.key),
                  trailing: Text(money(entry.value)),
                ),
              ),
            ],
          ],
        );
      });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDay = DateTime.now();
  @override
  Widget build(BuildContext context) => transactionData((context, snapshot) {
        if (snapshot.hasError)
          return ErrorMessage(
            message: 'Could not load calendar data: ${snapshot.error}',
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LoadingView();
        final items = (snapshot.data ?? <ExpenseTransaction>[])
            .where(
              (item) =>
                  item.date.year == selectedDay.year &&
                  item.date.month == selectedDay.month &&
                  item.date.day == selectedDay.day,
            )
            .toList();
        return ListView(
          children: [
            CalendarDatePicker(
              initialDate: selectedDay,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (value) => setState(() => selectedDay = value),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Transactions on ${dateText(selectedDay)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (items.isEmpty)
              const EmptyState(message: 'No transactions on this date.')
            else
              ...items.map((item) => TransactionTile(item: item)),
          ],
        );
      });
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CircleAvatar(radius: 40, child: Icon(Icons.person, size: 42)),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Expense Tracker User',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.currency_exchange),
              title: Text('Currency'),
              subtitle: Text('Pakistani Rupee (PKR)'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.storage),
              title: Text('Storage'),
              subtitle: Text('SQLite local offline database'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              subtitle: Text('Expense Tracker App – Version 1.0'),
            ),
          ),
        ],
      );
}

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Categories Management')),
        body: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Default categories available in this version.'),
            ),
            ...categories.map(
              (category) => ListTile(
                leading: const Icon(Icons.folder_outlined, color: primaryBlue),
                title: Text(category),
              ),
            ),
          ],
        ),
      );
}

class ChooseTransactionToEditScreen extends StatelessWidget {
  const ChooseTransactionToEditScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Choose Transaction to Edit')),
        body: transactionData((context, snapshot) {
          if (snapshot.hasError)
            return ErrorMessage(
              message: 'Could not load transactions: ${snapshot.error}',
            );
          if (snapshot.connectionState == ConnectionState.waiting)
            return const LoadingView();
          final items = snapshot.data ?? <ExpenseTransaction>[];
          if (items.isEmpty)
            return const EmptyState(
                message: 'No transactions available to edit.');
          return ListView(
            children: items
                .map(
                  (item) => ListTile(
                    leading: const Icon(Icons.edit, color: primaryBlue),
                    title: Text(item.title),
                    subtitle: Text('${item.category} • ${money(item.amount)}'),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TransactionFormScreen(item: item),
                        ),
                      );
                      notifyDataChanged();
                    },
                  ),
                )
                .toList(),
          );
        }),
      );
}

class SearchReportsScreen extends StatefulWidget {
  const SearchReportsScreen({super.key});
  @override
  State<SearchReportsScreen> createState() => _SearchReportsScreenState();
}

class _SearchReportsScreenState extends State<SearchReportsScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reports and Search')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search title, category or type',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    setState(() => query = value.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: transactionData((context, snapshot) {
                if (snapshot.hasError)
                  return ErrorMessage(
                    message: 'Could not search transactions: ${snapshot.error}',
                  );
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const LoadingView();
                final items = (snapshot.data ?? <ExpenseTransaction>[])
                    .where(
                      (item) =>
                          item.title.toLowerCase().contains(query) ||
                          item.category.toLowerCase().contains(query) ||
                          item.type.toLowerCase().contains(query) ||
                          item.note.toLowerCase().contains(query),
                    )
                    .toList();
                if (items.isEmpty)
                  return const EmptyState(message: 'No matching transactions.');
                return ListView(
                  children:
                      items.map((item) => TransactionTile(item: item)).toList(),
                );
              }),
            ),
          ],
        ),
      );
}

class FinancialReportsScreen extends StatelessWidget {
  const FinancialReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Financial Reports')),
        body: transactionData((context, snapshot) {
          if (snapshot.hasError)
            return ErrorMessage(
              message: 'Could not load reports: ${snapshot.error}',
            );
          if (snapshot.connectionState == ConnectionState.waiting)
            return const LoadingView();
          final items = snapshot.data ?? <ExpenseTransaction>[];
          final income = items
              .where((x) => x.type == 'Income')
              .fold<double>(0, (sum, x) => sum + x.amount);
          final expenses = items
              .where((x) => x.type == 'Expense')
              .fold<double>(0, (sum, x) => sum + x.amount);
          final maxY = (income > expenses ? income : expenses) * 1.2;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MetricCard(
                title: 'Total Income',
                amount: income,
                color: Colors.green,
              ),
              MetricCard(
                title: 'Total Expenses',
                amount: expenses,
                color: Colors.red,
              ),
              MetricCard(
                title: 'Net Balance',
                amount: income - expenses,
                color: primaryBlue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Income vs Expenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    maxY: maxY <= 0 ? 100 : maxY,
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: income,
                            color: Colors.green,
                            width: 35,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: expenses,
                            color: Colors.red,
                            width: 35,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              value.toInt() == 0
                                  ? 'Income'
                                  : value.toInt() == 1
                                      ? 'Expenses'
                                      : '',
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class ErrorMessage extends StatelessWidget {
  final String message;
  const ErrorMessage({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
