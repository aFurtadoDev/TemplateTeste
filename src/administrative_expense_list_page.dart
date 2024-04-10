// ignore_for_file: prefer_is_empty, unused_element

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:moneta/src/core/components/custom_snack_bar.dart';
import 'package:moneta/src/core/components/global_app_bar/global_scaffold.dart';
import 'package:moneta/src/core/components/list_no_result_found.dart';
import 'package:moneta/src/core/components/loadings/default_loading.dart';
import 'package:moneta/src/core/utils/global_action_type_enum.dart';
import 'package:moneta/src/shared/home/ui/pages/administrative_expense_reports/controllers/administrative_expense_detail_controller.dart';
import 'package:moneta/src/shared/home/ui/pages/administrative_expense_reports/controllers/administrative_expense_list_controller.dart';
import 'package:moneta/src/shared/home/ui/pages/administrative_expense_reports/controllers/attachments_controller.dart';
import 'package:moneta/src/shared/home/ui/pages/administrative_expense_reports/models/enums/expense_filter_options_enum.dart';
import 'package:moneta/src/shared/home/ui/pages/administrative_expense_reports/models/enums/expense_group_by_option_enum.dart';
import 'package:moneta/src/shared/home/ui/pages/administrative_expense_reports/models/enums/expense_status_code_enum.dart';
import 'package:moneta/src/shared/home/ui/pages/administrative_expense_reports/models/enums/expense_type_code_enum.dart';
import 'package:moneta/src/shared/home/ui/pages/administrative_expense_reports/models/expense_response_model.dart';
import 'package:moneta/src/shared/home/ui/pages/administrative_expense_reports/ui/pages/administrative_expense_details_page.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class AdministrativeExpenseListPage extends StatefulWidget {
  final int adminExpensePeriodReportId;
  final int adminExpenseReportId;
  final int adminExpenseGroupId;
  final int? adminExpenseEmployeeId;
  final String adminReportName;

  const AdministrativeExpenseListPage({
    Key? key,
    required this.adminExpensePeriodReportId,
    required this.adminExpenseReportId,
    required this.adminExpenseGroupId,
    this.adminExpenseEmployeeId,
    required this.adminReportName,
  }) : super(key: key);

  @override
  State<AdministrativeExpenseListPage> createState() =>
      _AdministrativeExpenseListPageState();
}

class _AdministrativeExpenseListPageState
    extends State<AdministrativeExpenseListPage> {
  late final AdministrativeExpenseListController controller;
  late final AdministrativeExpenseDetailsController controllerExpense;
  late final AttachmentsController controllerAttachments;

  final TextEditingController textEditingcontroller = TextEditingController();

  late String title;
  late String subTitle;
  late bool isCloseSearchable;
  late int reportId;
  int pageNumber = 1;
  final int pageSize = 10;
  late final ScrollController _scrollController;
  final DateFormat formatExpenseDate = DateFormat('dd/MM/yyyy');
  int _expenseGroupByOptionsEnum =
      AdminExpenseGroupByOptionEnum.expenseType.index;
  int _expenseSortedList = AdminExpenseGroupByOptionEnum.expenseDate.index;
  int _expenseFilteredOptionsEnum = ExpenseFilterOptionsEnum.pending.index;

  void _handleRadioValueChange(int value) {
    setState(() {
      _expenseGroupByOptionsEnum = value;
    });
  }

  void _handleRadioSortedValueChange(int value) async {
    await controller.getAllSpecificAdministrativeExpense(
        widget.adminExpenseReportId, false,
        pageNumber: pageNumber,
        pageSize: pageSize,
        employeeId: widget.adminExpenseEmployeeId,
        onlyPending: _expenseFilteredOptionsEnum == 0
            ? null
            : _expenseFilteredOptionsEnum == 1
                ? true
                : false,
        columnSort: getColumnSort(),
        columnSortDirection: 'desc');
    setState(() {
      _expenseSortedList = value;
    });
  }

  void _handleRadioFilteredValueChange(int value) async {
    await controller.getAllSpecificAdministrativeExpense(
      widget.adminExpenseReportId,
      false,
      pageNumber: pageNumber,
      pageSize: pageSize,
      employeeId: widget.adminExpenseEmployeeId,
      onlyPending: _expenseFilteredOptionsEnum == 0
          ? null
          : _expenseFilteredOptionsEnum == 1
              ? true
              : false,
      columnSort: getColumnSort(),
      columnSortDirection: 'desc',
    );
    setState(() {
      _expenseFilteredOptionsEnum = value;
    });
  }

  String getColumnSort() {
    var columnsFilter = '';
    if (_expenseSortedList == AdminExpenseGroupByOptionEnum.expenseDate.index) {
      columnsFilter = 'ExpenseDate';
    } else if (_expenseSortedList ==
        AdminExpenseGroupByOptionEnum.expenseType.index) {
      columnsFilter = 'ExpenseType';
    } else {
      columnsFilter = 'StatusCode';
    }

    return columnsFilter;
  }

  void loadMore() async {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        controller.resultResponse.totalPages! >= pageNumber) {
      if (controller.resultResponse.hasNextPage!) {
        pageNumber++;
      }
      await controller.getAllSpecificAdministrativeExpense(
          widget.adminExpenseReportId, true,
          pageNumber: pageNumber,
          pageSize: pageSize,
          employeeId: widget.adminExpenseEmployeeId,
          onlyPending: _expenseFilteredOptionsEnum == 0
              ? null
              : _expenseFilteredOptionsEnum == 1
                  ? true
                  : false,
          columnSort: getColumnSort(),
          columnSortDirection: 'desc');
    }
  }

  @override
  void initState() {
    isCloseSearchable = true;
    _scrollController = ScrollController();

    _scrollController.addListener(loadMore);

    controller = context.read<AdministrativeExpenseListController>();
    controllerExpense = context.read<AdministrativeExpenseDetailsController>();
    controllerAttachments = context.read<AttachmentsController>();

    controller.addListener(() {
      if (controller.state == AdministrativeExpenceListState.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            globalSnackBar(
              controller.exceptionMessage,
              Icons.error_outline,
              Colors.white,
              Colors.white,
              Colors.red,
            ),
          );
        }
      }
    });
    controllerExpense.addListener(() {
      if (controllerExpense.state == AdministrativeExpenceDetailsState.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            globalSnackBar(
              controllerExpense.exceptionMessage,
              Icons.error_outline,
              Colors.white,
              Colors.white,
              Colors.red,
            ),
          );
        }
      } else if (controllerExpense.state ==
          AdministrativeExpenceDetailsState.actionSuccess) {
        controller.getAllSpecificAdministrativeExpense(
            widget.adminExpenseReportId, false,
            pageNumber: pageNumber,
            pageSize: pageSize,
            employeeId: widget.adminExpenseEmployeeId,
            onlyPending: _expenseFilteredOptionsEnum == 0
                ? null
                : _expenseFilteredOptionsEnum == 1
                    ? true
                    : false,
            columnSort: getColumnSort(),
            columnSortDirection: 'desc');
      }
    });
    controllerAttachments.addListener(() {
      if (controllerAttachments.state == AttachmentsState.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            globalSnackBar(
              controllerAttachments.exceptionMessage,
              Icons.error_outline,
              Colors.white,
              Colors.white,
              Colors.red,
            ),
          );
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllSpecificAdministrativeExpense(
          widget.adminExpenseReportId, false,
          pageNumber: pageNumber,
          pageSize: pageSize,
          employeeId: widget.adminExpenseEmployeeId,
          onlyPending: _expenseFilteredOptionsEnum == 0
              ? null
              : _expenseFilteredOptionsEnum == 1
                  ? true
                  : false,
          columnSort: getColumnSort(),
          columnSortDirection: 'desc');
    });

    super.initState();

    title = widget.adminReportName;
    subTitle = 'Despesas Administrativas';
  }

  @override
  void dispose() {
    controller.adminExpenseReport.clear();
    controller.removeListener(() {});
    // controller.dispose();
    controllerExpense.removeListener(() {});
    // controllerExpense.dispose();
    controllerAttachments.removeListener(() {});
    // controllerAttachments.dispose();
    _scrollController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext contextPai) {
    return GlobalScaffold(
      title: title,
      subTitle: subTitle,
      isCloseSearchable: isCloseSearchable,
      isSearchable: true,
      isIconSearch: true,
      textFormField: searchTextField(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LiquidPullToRefresh(
          showChildOpacityTransition: true,
          animSpeedFactor: 5,
          color: Colors.green,
          height: 300,
          backgroundColor: const Color.fromARGB(110, 136, 190, 131),
          borderWidth: 2,
          onRefresh: () async =>
              await controller.getAllSpecificAdministrativeExpense(
                  widget.adminExpenseReportId, false,
                  pageNumber: pageNumber,
                  pageSize: pageSize,
                  onlyPending: _expenseFilteredOptionsEnum == 0
                      ? null
                      : _expenseFilteredOptionsEnum == 1
                          ? true
                          : false,
                  columnSort: getColumnSort(),
                  columnSortDirection: 'desc'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(
                  left: 10.0,
                  right: 10.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buttonOptions(),
                    _buttonAdd(),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Consumer<AdministrativeExpenseListController>(
                builder: (context, value, child) {
                  final adminExpenseReport =
                      sortList(_expenseSortedList, value.adminExpenseReport);

                  Map groupedItems = groupItems(adminExpenseReport);

                  // if (value.state == AdministrativeExpenceListState.loading) {
                  //   return const DefaultLoading();
                  // }
                  return groupedItems.length > 0
                      ? Expanded(
                          child: SlidableAutoCloseBehavior(
                            closeWhenOpened: true,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: _scrollController,
                              child: Column(
                                children: [
                                  groupedItems.length > 0
                                      ? ListView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          // controller: _scrollController,
                                          itemCount: groupedItems.length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            var expenseGroupName = groupedItems
                                                .keys
                                                .elementAt(index);
                                            List itemsInExpenseType =
                                                groupedItems[expenseGroupName]!;

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 15.0),
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 12,
                                                              top: 2,
                                                              right: 7,
                                                              bottom: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey.shade600,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(999),
                                                      ),
                                                      child: IntrinsicWidth(
                                                        child: Row(
                                                          // crossAxisAlignment: CrossAxisAlignment.center,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Expanded(
                                                              // flex: 6,
                                                              child: Text(
                                                                expenseGroupName
                                                                    .toString(),
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              'Total: ${itemsInExpenseType.length.toString()}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 5),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  ListView.separated(
                                                    separatorBuilder:
                                                        (context, index) =>
                                                            const Divider(
                                                      color: Color.fromARGB(
                                                          0, 255, 255, 255),
                                                      height: 6,
                                                    ),
                                                    key: Key(
                                                        itemsInExpenseType[0]
                                                            .name
                                                            .toString()),
                                                    shrinkWrap: true,
                                                    physics:
                                                        const ClampingScrollPhysics(),
                                                    itemCount:
                                                        itemsInExpenseType
                                                            .length,
                                                    itemBuilder:
                                                        (BuildContext context,
                                                            int index) {
                                                      ExpenseResponse item =
                                                          itemsInExpenseType[
                                                              index];

                                                      return _slidable(
                                                          itemsInExpenseType,
                                                          index,
                                                          item);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      : Visibility(
                                          visible: value.state ==
                                                  AdministrativeExpenceListState
                                                      .success &&
                                              groupedItems.length == 0,
                                          child: const ListNoResultsFound(
                                              labelText:
                                                  'Nenhuma despesa cadastrada...'),
                                        ),
                                  Visibility(
                                    visible: value.state ==
                                            AdministrativeExpenceListState
                                                .loading &&
                                        groupedItems.length == 0,
                                    child: const DefaultLoading(),
                                  ),
                                  Visibility(
                                    visible: value.state ==
                                            AdministrativeExpenceListState
                                                .loading &&
                                        groupedItems.length > 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      height: 35,
                                      width: 35,
                                      child: const CircularProgressIndicator(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const ListNoResultsFound(
                          labelText: 'Nenhuma despesa cadastrada...');
                },
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     await Navigator.of(context).push(
      //       MaterialPageRoute(
      //         builder: (context) => AdministrativeExpenseDetailsPage(
      //           adminExpense:
      //               ExpenseResponse.empty(widget.adminExpenseReportId),
      //           adminExpenseReportId: widget.adminExpensePeriodReportId,
      //           adminExpenseReportPeriodId: widget.adminExpenseReportId,
      //           globalActionTypeEnum: GlobalActionTypeEnum.include,
      //         ),
      //       ),
      //     );
      //     controller.getAllSpecificAdministrativeExpense(
      //         widget.adminExpenseReportId,
      //         pageNumber: pageNumber,
      //         pageSize: pageSize);
      //   },
      //   shape: const RoundedRectangleBorder(
      //     borderRadius: BorderRadius.all(
      //       Radius.circular(50),
      //     ),
      //   ),
      //   backgroundColor: Colors.green,
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  SizedBox _buttonOptions() {
    return SizedBox(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.only(
            left: 10,
            top: 2,
            right: 10,
            bottom: 2,
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.filter_list_sharp, size: 20),
            SizedBox(
              width: 5,
            ),
            Text(
              "Opções da lista",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        onPressed: () {
          _expenseGroupBySelect();
          setState(() {});
        },
      ),
    );
  }

  SizedBox _buttonAdd() {
    return SizedBox(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding:
              const EdgeInsets.only(left: 10, top: 2, right: 10, bottom: 2),
          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.circular(16)
          // )
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, size: 20),
            SizedBox(
              width: 5,
            ),
            Text(
              "Nova Despesa Administrativa",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdministrativeExpenseDetailsPage(
                adminExpense: ExpenseResponse.empty(
                    widget.adminExpenseReportId, widget.adminExpenseEmployeeId),
                adminExpenseReportId: widget.adminExpensePeriodReportId,
                adminExpenseReportPeriodId: widget.adminExpenseReportId,
                adminExpenseGroupId: widget.adminExpenseGroupId,
                adminExpenseEmployeeId: widget.adminExpenseEmployeeId,
                globalActionTypeEnum: GlobalActionTypeEnum.include,
              ),
            ),
          );
          controller.getAllSpecificAdministrativeExpense(
              widget.adminExpenseReportId, false,
              pageNumber: pageNumber,
              pageSize: pageSize,
              employeeId: widget.adminExpenseEmployeeId,
              onlyPending: _expenseFilteredOptionsEnum == 0
                  ? null
                  : _expenseFilteredOptionsEnum == 1
                      ? true
                      : false,
              columnSort: getColumnSort(),
              columnSortDirection: 'desc');
        },
      ),
    );
  }

  Slidable _slidable(
      List<dynamic> itemsInExpenseType, int index, ExpenseResponse item) {
    return Slidable(
      startActionPane: itemsInExpenseType[index].permission.canUpdate == false
          ? null
          : ActionPane(
              extentRatio: 0.25,
              motion: const ScrollMotion(),
              // motion: const BehindMotion(),
              children: [
                SlidableButton(
                  backgroundColor: const Color.fromARGB(255, 217, 15, 15),
                  fontSize: 12,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Excluir',
                  onPressed: (context) {
                    _onDelete(context, itemsInExpenseType[index]);
                  },
                ),
              ],
            ),
      endActionPane: ActionPane(
        extentRatio: itemsInExpenseType[index].permission.canUpdate == false
            ? 0.27
            : 0.54,
        motion: const ScrollMotion(),
        children: [
          Container(
            child: itemsInExpenseType[index].permission.canUpdate == false
                ? null
                : SlidableButton(
                    backgroundColor: const Color.fromARGB(255, 23, 97, 147),
                    fontSize: 12,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Editar',
                    onPressed: (context) {
                      _onUpdate(itemsInExpenseType[index]);
                    },
                  ),
          ),
          SlidableButton(
            backgroundColor: const Color.fromARGB(255, 15, 194, 226),
            fontSize: 12,
            foregroundColor: Colors.white,
            icon: Icons.remove_red_eye,
            label: 'Visualizar',
            onPressed: (context) async {
              await controllerExpense
                  .getAdministrativeExpenseById(itemsInExpenseType[index].id!);
              ExpenseResponse expense = controllerExpense.adminExpense;

              setState(() {
                if (controllerExpense.state ==
                    AdministrativeExpenceDetailsState.error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    globalSnackBar(
                      controllerExpense.exceptionMessage,
                      Icons.error_outline,
                      Colors.white,
                      Colors.white,
                      Colors.red,
                    ),
                  );
                } else {
                  _onViewer(expense);
                }
              });
            },
          ),
        ],
      ),
      child: BuildListTitle(item: item),
    );
  }

  Future<dynamic> _onDelete(BuildContext context, ExpenseResponse common) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5))),
        title: const Text(
          'Excluir Despesa',
          style: TextStyle(fontSize: 16),
        ),
        content: Text.rich(
          softWrap: true,
          TextSpan(
            style: const TextStyle(
              fontSize: 14,
            ),
            text: 'Deseja confirmar a exclusão da despesa ',
            children: [
              TextSpan(
                text: '"${common.id} - ${common.name}"',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '?',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              elevation: 1.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              elevation: 1.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            onPressed: () async {
              await controller.deleteExpenseById(common.id!);

              setState(() {
                if (controller.state == AdministrativeExpenceListState.error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      globalSnackBar(
                        controller.exceptionMessage,
                        Icons.error_outline,
                        Colors.white,
                        Colors.white,
                        Colors.red,
                      ),
                    );
                  }
                } else if (controller.state ==
                    AdministrativeExpenceListState.success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      globalSnackBar(
                        'Registro excluido com sucesso',
                        Icons.check,
                        Colors.white,
                        Colors.white,
                        Colors.green.shade600,
                      ),
                    );
                  }
                } else if (controller.state ==
                    AdministrativeExpenceListState.warning) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      globalSnackBar(
                        controller.exceptionMessage,
                        Icons.warning_amber,
                        Colors.black,
                        Colors.black,
                        Colors.orange.shade600,
                      ),
                    );
                  }
                } else if (controller.state ==
                    AdministrativeExpenceListState.loading) {
                  const DefaultLoading();
                }
                controller.getAllSpecificAdministrativeExpense(
                    widget.adminExpenseReportId, false,
                    pageNumber: pageNumber,
                    pageSize: pageSize,
                    employeeId: widget.adminExpenseEmployeeId,
                    onlyPending: _expenseFilteredOptionsEnum == 0
                        ? null
                        : _expenseFilteredOptionsEnum == 1
                            ? true
                            : false,
                    columnSort: getColumnSort(),
                    columnSortDirection: 'desc');
                Navigator.of(context).pop();
              });
            },
          ),
        ],
      ),
    );
  }

  void _onUpdate(ExpenseResponse common) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdministrativeExpenseDetailsPage(
          adminExpense: common,
          adminExpenseReportId: widget.adminExpensePeriodReportId,
          adminExpenseReportPeriodId: widget.adminExpenseReportId,
          adminExpenseGroupId: widget.adminExpenseGroupId,
          globalActionTypeEnum: GlobalActionTypeEnum.update,
        ),
      ),
    );

    await controller.getAllSpecificAdministrativeExpense(
        widget.adminExpenseReportId, false,
        pageNumber: pageNumber,
        pageSize: pageSize,
        employeeId: widget.adminExpenseEmployeeId,
        onlyPending: _expenseFilteredOptionsEnum == 0
            ? null
            : _expenseFilteredOptionsEnum == 1
                ? true
                : false,
        columnSort: getColumnSort(),
        columnSortDirection: 'desc');
  }

  void _onViewer(ExpenseResponse common) {
    final formatCurrency =
        NumberFormat.currency(locale: "pt_BR", symbol: "R\$");

    DateFormat formatDefaultDate = DateFormat('dd/MM/yyyy');

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 4.0,
                  width: 36.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFF618a4f),
                    borderRadius: BorderRadius.all(
                      Radius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black54,
                        width: 1.0,
                      ),
                    ),
                  ),
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 5.0),
                    child: Text(
                      'Detalhes da Despesa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'Status:',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Identificador:',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'Tipo da Despesa:',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'Descrição:',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              const Text(
                                'Data da Despesa:',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              const Text(
                                'Centro de Custo:',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'Natureza:',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Visibility(
                                visible: common.expenseType!.expenseTypeCode ==
                                    ExpenseTypeCodeEnum.displacement.index,
                                child: const Text(
                                  'Trecho Pré-Cadastrado:',
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                              ),
                              Visibility(
                                visible: common.expenseType!.expenseTypeCode ==
                                    ExpenseTypeCodeEnum.displacement.index,
                                child: const Text(
                                  'Quilometragem:',
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                              ),
                              Visibility(
                                visible: common.expenseType!.expenseTypeCode !=
                                    ExpenseTypeCodeEnum.displacement.index,
                                child: const Text(
                                  'Quantidade:',
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                              ),
                              const Text(
                                'Valor Unitário:',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'Valor Total:',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'Observação:',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Campo Status
                              Text(
                                common.statusName,
                                // ExpenseStatusCodeEnum.values[common.statusCode!]
                                //     .displayExpenseStatusCodeName,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // Campo Identificador
                              Text(
                                common.id.toString(),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              // Campo Tipo de Despesa
                              Text(
                                common.expenseTypeName!,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              // Campo Descrição
                              Text(
                                common.name == null
                                    ? '-----'
                                    : common.name.toString(),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              // Campo Data
                              Text(
                                formatDefaultDate.format(DateTime.parse(
                                    common.expenseDate.toString())),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              // Campo Centro de Custo
                              Text(
                                common.costCenter!.costCenterCode == null
                                    ? ''
                                    : common.costCenterFullName,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              // Campo Natureza
                              Text(
                                common.budgetNature!.budgetCode == null
                                    ? ''
                                    : common
                                        .budgetNatureFullName, //'${common.budgetNature!.budgetCode} - ${common.budgetNature!.description}',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87),
                              ),
                              // Campo Trechos
                              Visibility(
                                visible: common.expenseType!.expenseTypeCode ==
                                    ExpenseTypeCodeEnum.displacement.index,
                                child: Text(
                                  common.registeredStretch?.name == null
                                      ? ''
                                      : common.registeredStretchFullName,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87),
                                ),
                              ),
                              Visibility(
                                visible: common.expenseType!.expenseTypeCode ==
                                    ExpenseTypeCodeEnum.displacement.index,
                                child: Text(
                                  common.registeredStretch?.name == null
                                      ? ''
                                      : common.mileageValue != null
                                          ? '${double.parse(common.mileageValue.toString())}'
                                          : double.parse(common
                                                  .registeredStretch!
                                                  .mileageValue
                                                  .toString())
                                              .toString(),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87),
                                ),
                              ),
                              Visibility(
                                visible: common.expenseType!.expenseTypeCode !=
                                    ExpenseTypeCodeEnum.displacement.index,
                                child: Text(
                                  '${common.quantity!.toInt()}',
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87),
                                ),
                              ),
                              // Campo Valor Unitário
                              Text(
                                formatCurrency.format(
                                    double.parse(common.unitValue.toString())),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87),
                              ),
                              // Campo Valor Total
                              Text(
                                formatCurrency.format(double.parse(
                                    common.expenseValue.toString())),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87),
                              ),
                              // Campo Observação
                              Text(
                                '${common.description}',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black54,
                        width: 1.0,
                      ),
                    ),
                  ),
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 5.0),
                    child: Text(
                      'Arquivos Anexados',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: common.attachments!.length > 0
                      ? ListView.separated(
                          padding: const EdgeInsets.all(0),
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return Container(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8.0),
                              // color: Colors.amber,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(0),
                                dense: true,
                                title: common.attachments!.isNotEmpty
                                    ? Text(
                                        common.attachments![index]
                                            .attachmentName!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      )
                                    : const Text(''),
                                subtitle: common.attachments!.isNotEmpty
                                    ? Text(
                                        common.attachments![index]
                                                    .documentSize ==
                                                null
                                            ? '0 KB'
                                            : common.attachments![index]
                                                .documentSize!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                        ),
                                      )
                                    : const Text(''),
                                leading:
                                    const Icon(Icons.attach_file, size: 20),
                                trailing: SizedBox(
                                  width: 30,
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          await controllerAttachments
                                              .getAttachmentsById(common
                                                  .attachments![index].id!);
                                          setState(() {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  child: PhotoView(
                                                    tightMode: true,
                                                    imageProvider: MemoryImage(
                                                      base64Decode(
                                                        controllerAttachments
                                                            .attachments
                                                            .documentData!
                                                            .replaceAll(
                                                                'data:${controllerAttachments.attachments.documentType};base64,',
                                                                ''),
                                                      ),
                                                    ),
                                                    heroAttributes:
                                                        const PhotoViewHeroAttributes(
                                                            tag: "someTag"),
                                                  ),
                                                );
                                              },
                                            );
                                          });
                                        },
                                        child: const Icon(
                                          Icons.remove_red_eye_outlined,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => const Divider(
                            color: Colors.white,
                            height: 5,
                          ),
                          itemCount: common.attachments!.length,
                        )
                      : const ListNoResultsFound(
                          labelText: 'Nenhum anexo cadastrado...'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _expenseGroupBySelect() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    height: 4.0,
                    width: 36.0,
                    decoration: const BoxDecoration(
                      color: Colors.blueGrey,
                      borderRadius: BorderRadius.all(
                        Radius.circular(2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        textAlign: TextAlign.center,
                        'Utilize as opções abaixo para manipular os dados da lista de despesas para melhor visualização.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.black45),
                      const Text(
                        'Selecione a opção para agrupar os dados da lista: ',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: 0.8,
                            child: Radio(
                              value: 0,
                              groupValue: _expenseGroupByOptionsEnum,
                              onChanged: (value) {
                                setState(() {
                                  _expenseGroupByOptionsEnum = value!;
                                });
                                _handleRadioValueChange(value!);
                              },
                            ),
                          ),
                          const Text(
                            'Tipo de Despesa',
                            style: TextStyle(fontSize: 10.0),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Radio(
                              value: 1,
                              groupValue: _expenseGroupByOptionsEnum,
                              onChanged: (value) {
                                setState(() {
                                  _expenseGroupByOptionsEnum = value!;
                                });
                                _handleRadioValueChange(value!);
                              },
                            ),
                          ),
                          const Text(
                            'Data da Despesa',
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Radio(
                              value: 2,
                              groupValue: _expenseGroupByOptionsEnum,
                              onChanged: (value) {
                                setState(() {
                                  _expenseGroupByOptionsEnum = value!;
                                });
                                _handleRadioValueChange(value!);
                              },
                            ),
                          ),
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black45),
                      const Text(
                        'Selecione a opção que deseja ordenar os dados da lista: ',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: 0.8,
                            child: Radio(
                              value: 0,
                              groupValue: _expenseSortedList,
                              onChanged: (value) {
                                setState(() {
                                  _expenseSortedList = value!;
                                });
                                _handleRadioSortedValueChange(value!);
                              },
                            ),
                          ),
                          const Text(
                            'Tipo de Despesa',
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Radio(
                              value: 1,
                              groupValue: _expenseSortedList,
                              onChanged: (value) {
                                setState(() {
                                  _expenseSortedList = value!;
                                });
                                _handleRadioSortedValueChange(value!);
                              },
                            ),
                          ),
                          const Text(
                            'Data da Despesa',
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Radio(
                              value: 2,
                              groupValue: _expenseSortedList,
                              onChanged: (value) {
                                setState(() {
                                  _expenseSortedList = value!;
                                });
                                _handleRadioSortedValueChange(value!);
                              },
                            ),
                          ),
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.black45),
                      const Text(
                        'Selecione a opção que deseja filtrar os dados da lista: ',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: 0.8,
                            child: Radio(
                              value: 0,
                              groupValue: _expenseFilteredOptionsEnum,
                              onChanged: (value) {
                                setState(() {
                                  _expenseFilteredOptionsEnum = value!;
                                });
                                _handleRadioFilteredValueChange(value!);
                              },
                            ),
                          ),
                          const Text(
                            'Todos',
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Radio(
                              value: 1,
                              groupValue: _expenseFilteredOptionsEnum,
                              onChanged: (value) {
                                setState(() {
                                  _expenseFilteredOptionsEnum = value!;
                                });
                                _handleRadioFilteredValueChange(value!);
                              },
                            ),
                          ),
                          const Text(
                            'Pendentes',
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Radio(
                              value: 2,
                              groupValue: _expenseFilteredOptionsEnum,
                              onChanged: (value) {
                                setState(() {
                                  _expenseFilteredOptionsEnum = value!;
                                });
                                _handleRadioFilteredValueChange(value!);
                              },
                            ),
                          ),
                          const Text(
                            'Finalizados',
                            style: TextStyle(
                              fontSize: 10.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  List<ExpenseResponse> sortList(int option, List<ExpenseResponse> objectList) {
    List<ExpenseResponse> list = objectList;
    if (list.length > 0) {
      if (option == AdminExpenseGroupByOptionEnum.expenseType.index) {
        list = objectList.toList().sorted((a, b) => a.expenseType!.name
            .toString()
            .compareTo(b.expenseType!.name.toString()));
      } else if (option == AdminExpenseGroupByOptionEnum.expenseDate.index) {
        list = objectList
            .toList()
            .sorted((a, b) => b.expenseDate!.compareTo(a.expenseDate!));
      } else if (option == AdminExpenseGroupByOptionEnum.expenseStatus.index) {
        list = objectList
            .toList()
            .sorted((a, b) => a.statusName!.compareTo(b.statusName!));
      }
    }

    return list;
  }

  Map groupItems(List items) {
    var groupReturn;

    if (_expenseGroupByOptionsEnum ==
        AdminExpenseGroupByOptionEnum.expenseType.index) {
      groupReturn = groupBy(items, (item) => item.expenseType.name);
    } else if (_expenseGroupByOptionsEnum ==
        AdminExpenseGroupByOptionEnum.expenseDate.index) {
      groupReturn = groupBy(
          items,
          (item) => formatExpenseDate
              .format(DateTime.parse(item.expenseDate.toString())));
    } else if (_expenseGroupByOptionsEnum ==
        AdminExpenseGroupByOptionEnum.expenseStatus.index) {
      groupReturn = groupBy(
          items,
          (item) => ExpenseStatusCodeEnum
              .values[item.statusCode].displayExpenseStatusCodeName);
    }
    return groupReturn;
  }

  Widget searchTextField() {
    return SizedBox(
      height: 40,
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        controller: textEditingcontroller,
        autofocus: true,
        cursorColor: const Color.fromARGB(255, 4, 74, 18),
        style: const TextStyle(
          color: Color.fromARGB(255, 4, 74, 18),
          fontSize: 12,
        ),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: const UnderlineInputBorder(),
          labelText: 'Buscar',
          labelStyle: const TextStyle(
              fontSize: 12, color: Color.fromARGB(255, 4, 74, 18)),
          isDense: false,
          suffixIcon: IconButton(
            padding: const EdgeInsets.only(top: 0),
            iconSize: 18,
            icon: const Icon(
              Icons.cancel,
              size: 18,
              color: Color.fromARGB(255, 4, 74, 18),
            ),
            tooltip: 'Buscar',
            onPressed: () {
              setState(() {
                isCloseSearchable = true;
                if (textEditingcontroller.value.text.isNotEmpty) {
                  textEditingcontroller.clear.call();
                  controller.getAllSpecificAdministrativeExpense(
                      widget.adminExpenseReportId, false,
                      pageNumber: pageNumber,
                      pageSize: pageSize,
                      employeeId: widget.adminExpenseEmployeeId,
                      onlyPending: _expenseFilteredOptionsEnum == 0
                          ? null
                          : _expenseFilteredOptionsEnum == 1
                              ? true
                              : false,
                      columnSort: getColumnSort(),
                      columnSortDirection: 'desc');
                }
              });
            },
          ),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white)),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white)),
        ),
        onChanged: (value) {
          controller.getSpecificAdministrativeExpenseByFilter(
              widget.adminExpenseReportId,
              columnsFilter: value);
        },
      ),
    );
  }
}

class BuildListTitle extends StatelessWidget {
  final ExpenseResponse item;

  const BuildListTitle({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatCurrency =
        NumberFormat.currency(locale: "pt_BR", symbol: "R\$");

    final formatDecimalLabel = NumberFormat.currency(
        locale: 'pt_BR', symbol: '', customPattern: '#,##0.00');

    DateFormat formatDefaultDate = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                  text: '${item.id!}',
                  children: [
                    TextSpan(
                      text: ' - ${item.expenseType!.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.expenseDate == null
                    ? ''
                    : formatDefaultDate
                        .format(DateTime.parse(item.expenseDate.toString())),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(
              top: 6.0,
              left: 4.0,
              bottom: 6.0,
              right: 4.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text.rich(
                        softWrap: true,
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                          text: '',
                          children: [
                            WidgetSpan(
                              child: Container(
                                padding: const EdgeInsets.only(
                                    left: 7, top: 0, right: 7, bottom: 0),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(item.statusCode),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: IntrinsicWidth(
                                  child: Text(
                                    ExpenseStatusCodeEnum
                                        .values[item.statusCode!]
                                        .displayExpenseStatusCodeName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.name == null ? '-----' : item.name.toString(),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        item.costCenter!.costCenterCode == null
                            ? ''
                            : '${item.costCenter!.costCenterCode.toString()} - ${item.costCenter!.costCenterName.toString()}',
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                      ),
                      Text(
                        item.budgetNature!.budgetCode == null
                            ? ''
                            : '${item.budgetNature!.budgetCode} - ${item.budgetNature!.description}',
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87),
                      ),
                      item.expenseType!.expenseTypeCode ==
                              ExpenseTypeCodeEnum.displacement.index
                          ? Text(
                              item.registeredStretch?.name == null
                                  ? ''
                                  : '${item.registeredStretch?.name} - ${formatDecimalLabel.format(double.parse(item.registeredStretch!.mileageValue.toString()))} km',
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87),
                            )
                          : const SizedBox(),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const CustomTextBlanc(),
                      const SizedBox(height: 5),
                      const Text(
                        'Valor Total',
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        formatCurrency
                            .format(double.parse(item.expenseValue.toString())),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                      const CustomTextBlanc(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            final slidable = Slidable.of(context);
            final isClosed =
                slidable?.actionPaneType.value == ActionPaneType.none;
            if (isClosed) {
              slidable?.openEndActionPane();
            } else {
              slidable?.close();
            }
          },
        ),
      ),
    );
  }

  /*
Pendente de Primeira Aprovação = 0, 
Pendente de Segunda Aprovação = 1, 
Aguardando Aprovação 2 Fora de Prazo = 2,
Aprovado = 3,
Aprovado Depois do Prazo (Segunda aprovação) = 4,
Reprovado = 5,
Glosado = 6,
Aprovado e Integrado RM= 7,
 */

  _getStatusColor(expenseStatusCode) {
    var statusColor = Colors.black87;
    switch (expenseStatusCode) {
      case 0:
        statusColor = Colors.blue.shade300;
        break;
      case 1:
        statusColor = Colors.blue.shade300;
        break;
      case 2:
        statusColor = Colors.orange.shade300;
        break;
      case 3:
        statusColor = Colors.blueAccent.shade400;
        break;
      case 4:
        statusColor = Colors.green.shade200;
        break;
      case 5:
        statusColor = Colors.red.shade300;
        break;
      case 6:
        statusColor = Colors.orangeAccent.shade400;
        break;
      case 7:
        statusColor = Colors.greenAccent.shade400;
        break;
    }
    return statusColor;
    // approvalPending1, // 0 Pendente 1° Aprovação
    // approvalOneOutOfDeadline, // 1 Aguardando 1° Aprovação Fora de Prazo
    // approvalPending2, // 2 Pendente 2° Aprovação
    // approvalTwoOutOfDeadline, // 3 Aguardando Aprovação 2 Fora de Prazo
    // approved, // 4 Aprovado
    // approvedAfterDeadline, // 5 Aprovado Depois do Prazo (Segunda aprovação)
    // reproved, // 6 Reprovado
    // glossed // 7 Glosada
  }
}

class SlidableButton extends StatelessWidget {
  final IconData? icon;
  final double? iconSize;
  final double? fontSize;
  final String? label;

  /// The amount of space the child's can occupy in the main axis is
  /// determined by dividing the free space according to the flex factors of the
  /// other [CustomSlidableAction]s.
  final int flex;

  final Color? backgroundColor;
  Color? borderColor;
  final Color? foregroundColor;

  /// Whether the enclosing [Slidable] will be closed after [onPressed]
  /// occurred.
  final bool autoClose;

  /// Called when the action is tapped or otherwise activated.
  /// If this callback is null, then the action will be disabled.
  final SlidableActionCallback? onPressed;

  SlidableButton({
    Key? key,
    this.icon,
    this.iconSize,
    this.fontSize,
    this.label,
    this.flex = 1,
    this.backgroundColor,
    this.borderColor,
    this.foregroundColor,
    this.autoClose = true,
    required this.onPressed,
  }) : super(key: key) {
    borderColor ??= backgroundColor ?? Colors.transparent;
  }

  void _handleTap(BuildContext context) {
    onPressed?.call(context);
    if (autoClose) {
      Slidable.of(context)?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gets the SlidableController.
    final controller = Slidable.of(context);

    return ValueListenableBuilder<double>(
      // Listens to the slide animation.
      valueListenable: controller!.animation,
      builder: (context, value, child) {
        // This is the maximum ratio allowed by the current action pane.
        final maxRatio = controller.actionPaneConfigurator!.extentRatio;
        final double opacity = value / maxRatio;
        return Flexible(
          flex: flex,
          fit: FlexFit.tight,
          child: Container(
            margin: const EdgeInsets.fromLTRB(1, 5, 4, 3),
            child: OutlinedButton(
              onPressed: () => _handleTap(context),
              style: OutlinedButton.styleFrom(
                elevation: 8,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                minimumSize: Size.zero,
                backgroundColor: backgroundColor?.withOpacity(opacity / 1.5),
                // shadowColor: const Color.fromARGB(255, 88, 88, 88),

                side: BorderSide(
                  color: borderColor!.withOpacity(opacity),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon,
                      size: iconSize,
                      color: foregroundColor?.withOpacity(opacity)),
                  Text(
                    label ?? '',
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: foregroundColor?.withOpacity(opacity),
                        //fontWeight: FontWeight.w300,
                        fontSize: fontSize),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomTextBlanc extends StatelessWidget {
  const CustomTextBlanc({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      '',
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    );
  }
}
