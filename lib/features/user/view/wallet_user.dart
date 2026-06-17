import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rido_syria_app/core/styles/themes.dart';
import 'package:rido_syria_app/core/widgets/app_bar.dart';
import 'package:rido_syria_app/features/user/cubit/cubit.dart';
import 'package:rido_syria_app/features/user/cubit/states.dart';

class WalletUserView extends StatelessWidget {
  const WalletUserView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserCubit()
        ..getWallet(context: context)
        ..getWalletTransactions(context: context),
      child: BlocConsumer<UserCubit, UserStates>(
        listener: (context, state) {},
        builder: (context, state) {
          final cubit = UserCubit.get(context);
          final isLoadingWallet = state is GetWalletLoadingState;
          final isLoadingTransactions = state is GetWalletTransactionsLoadingState;

          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Scaffold(
                body: Column(
                  children: [
                    const CustomAppBarBack(),
                    Expanded(
                      child: RefreshIndicator(
                        color: secondPrimaryColor,
                        onRefresh: () async {
                          cubit.getWallet(context: context);
                          cubit.getWalletTransactions(context: context);
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _BalanceCard(
                                amount: cubit.walletBalance,
                                loading: isLoadingWallet,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'حركات المحفظة',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ConditionalBuilder(
                                condition: !isLoadingTransactions,
                                builder: (context) {
                                  if (cubit.walletTransactions.isEmpty) {
                                    return _EmptyTransactions();
                                  }
                                  return Column(
                                    children: cubit.walletTransactions
                                        .map((tx) => _TransactionTile(tx: tx))
                                        .toList(),
                                  );
                                },
                                fallback: (context) => const _TransactionsLoading(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.amount, required this.loading});

  final double amount;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: secondPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.wallet_2, color: secondPrimaryColor, size: 24),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'رصيد المحفظة',
                style: TextStyle(
                  fontSize: 12,
                  color: secondPrimaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (loading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: secondPrimaryColor,
                  ),
                )
              else
                Text(
                  '${amount.toStringAsFixed(0)} IQD ',
                  style: const TextStyle(
                    fontSize: 20,
                    color: primaryTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final type = (tx['type'] ?? '').toString();
    final isCredit = type == 'credit';
    final amount = (tx['amount'] ?? 0).toString();
    final date = (tx['createdAt'] ?? '').toString();
    final note = (tx['note'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isCredit ? Colors.green : Colors.red).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Iconsax.arrow_down_2 : Iconsax.arrow_up_3,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isCredit ? 'إضافة رصيد' : 'خصم رصيد',
                style: const TextStyle(
                  fontSize: 13,
                  color: primaryTextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$amount د.ع',
                style: TextStyle(
                  fontSize: 12,
                  color: isCredit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  note,
                  style: const TextStyle(
                    fontSize: 10,
                    color: secondPrimaryTextColor,
                  ),
                ),
              ],
              if (date.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 10,
                    color: secondPrimaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: const Column(
        children: [
          Icon(Iconsax.receipt_1, size: 24, color: secondPrimaryTextColor),
          SizedBox(height: 8),
          Text(
            'لا توجد حركات محفظة حاليا',
            style: TextStyle(
              fontSize: 12,
              color: secondPrimaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsLoading extends StatelessWidget {
  const _TransactionsLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: CircularProgressIndicator(
          color: secondPrimaryColor,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
