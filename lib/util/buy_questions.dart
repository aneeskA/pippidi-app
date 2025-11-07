import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pippidi/data/questions.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pippidi/util/constants.dart';
import 'package:pippidi/ui/mybutton.dart';

class BuyQuestions extends StatefulWidget {
  final String category;
  final String text;
  final String product;
  final int count;
  final Function callback;

  BuyQuestions({
    super.key,
    required this.category,
    required this.text,
    required this.product,
    required this.count,
    required this.callback,
  });

  @override
  State<BuyQuestions> createState() => _BuyQuestionsState();
}

class _BuyQuestionsState extends State<BuyQuestions> {
  bool _isLoading = false;

  FToast fToast = FToast();

  void buyMoreQuestions() async {
    setState(
      () {
        _isLoading = true;
      },
    );

    try {
      final products = await Purchases.getProducts(
        [widget.product],
        productCategory: ProductCategory.nonSubscription,
      );
      if (products.isEmpty) {
        throw PlatformException(
          code: 'PRODUCT_NOT_FOUND',
          message: 'Product not found: '
              '${widget.product}',
        );
      }
      final StoreProduct storeProduct = products.first;
      await Purchases.purchaseStoreProduct(storeProduct);
      Questions().raiseAvailableLimit(widget.category, widget.count);
      // alert on successful buy
      Widget okButton = TextButton(
        child: Text(
          Malayalam.ok,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          // Add a small delay to ensure dialog is fully closed before navigation
          Future.delayed(const Duration(milliseconds: 200), () {
            widget.callback();
          });
        },
      );
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.deepPurple,
            title: Text(
              Malayalam.great,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            content: Text(
              Malayalam.purchasedQuestions(widget.count),
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            actions: [
              okButton,
            ],
          );
        },
        barrierDismissible: false,
      );

      FirebaseAnalytics.instance.logPurchase(items: [
        AnalyticsEventItem(
          itemCategory: widget.category,
          itemId: widget.product,
        )
      ]);
      // navigate to next page
    } on PlatformException catch (e) {
      print(e);
      String errorMessage = '';
      var errorCodeString = e.code;
      switch (errorCodeString) {
        case 'purchaseCancelledError':
          errorMessage = Malayalam.purchaseCancelled;
          break;
        case 'purchaseNotAllowedError':
          errorMessage = Malayalam.purchaseNotAllowed;
          break;
        case 'PRODUCT_NOT_FOUND':
          errorMessage = Malayalam.purchaseError;
          break;
        default:
          errorMessage = Malayalam.purchaseError;
          break;
      }
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.deepPurple,
            title: Text(
              Malayalam.purchaseError,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            content: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  Malayalam.ok,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
        barrierDismissible: false,
      );

      FirebaseAnalytics.instance.logRemoveFromCart(items: [
        AnalyticsEventItem(
          itemId: widget.product,
          itemCategory: widget.category,
        )
      ]);
    }

    setState(
      () {
        _isLoading = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyButton(
      text: widget.text,
      myColor: Colors.deepPurple.shade900,
      callBack: buyMoreQuestions,
      isLoading: _isLoading,
    );
  }
}
