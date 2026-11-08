package com.delivery.tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar

class OrderWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, OrderWidgetProvider::class.java))
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val recordsJson = prefs.getString("flutter.records", "[]") ?: "[]"
            val gasJson = prefs.getString("flutter.gasEntries", "[]") ?: "[]"
            val orderPrice = if (prefs.contains("flutter.orderPrice")) prefs.getFloat("flutter.orderPrice", 10.0f).toDouble() else 10.0
            val dailyRent = if (prefs.contains("flutter.dailyRent")) prefs.getFloat("flutter.dailyRent", 40.0f).toDouble() else 40.0

            val cal = Calendar.getInstance()
            val curMonth = cal.get(Calendar.MONTH) + 1
            val curYear = cal.get(Calendar.YEAR)

            var totalOrders = 0
            var totalGross = 0.0
            var recordedDays = 0

            try {
                val arr = JSONArray(recordsJson)
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    val dateStr = obj.getString("date")
                    val year = dateStr.substring(0, 4).toInt()
                    val month = dateStr.substring(5, 7).toInt()
                    if (year == curYear && month == curMonth) {
                        val isWorkDay = obj.getBoolean("isWorkDay")
                        val orders = obj.getInt("ordersCount")
                        if (isWorkDay) {
                            totalOrders += orders
                            totalGross += orders * orderPrice
                        }
                        recordedDays += 1
                    }
                }
            } catch (e: Exception) {
                // تجاهل أي خطأ تحليل، تبقى الأرقام صفر بدل ما يتعطل الودجت
            }

            var totalGas = 0.0
            try {
                val gasArr = JSONArray(gasJson)
                for (i in 0 until gasArr.length()) {
                    val obj = gasArr.getJSONObject(i)
                    val dateStr = obj.getString("date")
                    val year = dateStr.substring(0, 4).toInt()
                    val month = dateStr.substring(5, 7).toInt()
                    if (year == curYear && month == curMonth) {
                        totalGas += obj.getDouble("amount")
                    }
                }
            } catch (e: Exception) {
            }

            val netIncome = totalGross - (recordedDays * dailyRent) - totalGas

            val monthNames = arrayOf(
                "", "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
                "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
            )

            val views = RemoteViews(context.packageName, R.layout.order_widget)
            views.setTextViewText(R.id.widget_month_label, "إحصائيات شهر ${monthNames[curMonth]}")
            views.setTextViewText(R.id.widget_orders, "$totalOrders طلب")
            views.setTextViewText(R.id.widget_net, "صافي الربح: ${netIncome.toInt()} ريال")

            val netColor = if (netIncome >= 0) 0xFF2FBE77.toInt() else 0xFFE0555F.toInt()
            views.setTextColor(R.id.widget_net, netColor)

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = android.app.PendingIntent.getActivity(
                context, 0, launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
