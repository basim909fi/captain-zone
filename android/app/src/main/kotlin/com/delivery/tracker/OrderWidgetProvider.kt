package com.delivery.tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
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
            try {
                val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                val recordsJson = prefs.getString("flutter.records", "[]") ?: "[]"
                val gasJson = prefs.getString("flutter.gasEntries", "[]") ?: "[]"
                val otherJson = prefs.getString("flutter.otherExpenses", "[]") ?: "[]"
                val activeShiftJson = prefs.getString("flutter.activeShift", null)

                val orderPrice = when {
                    prefs.contains("flutter.orderPrice") -> {
                        try {
                            prefs.getFloat("flutter.orderPrice", 10.0f).toDouble()
                        } catch (_: Exception) {
                            prefs.getInt("flutter.orderPrice", 10).toDouble()
                        }
                    }
                    else -> 10.0
                }

                val dailyRent = when {
                    prefs.contains("flutter.dailyRent") -> {
                        try {
                            prefs.getFloat("flutter.dailyRent", 40.0f).toDouble()
                        } catch (_: Exception) {
                            prefs.getInt("flutter.dailyRent", 40).toDouble()
                        }
                    }
                    else -> 40.0
                }

                val dailyTarget = when {
                    prefs.contains("flutter.dailyTarget") -> prefs.getInt("flutter.dailyTarget", 16)
                    else -> 16
                }

                val cal = Calendar.getInstance()
                val curYear = cal.get(Calendar.YEAR)
                val curMonth = cal.get(Calendar.MONTH) + 1
                val curDay = cal.get(Calendar.DAY_OF_MONTH)
                val todayStr = String.format("%04d-%02d-%02d", curYear, curMonth, curDay)

                var isShiftOpen = false
                var todayOrders = 0
                var activeOrderPrice = orderPrice

                if (!activeShiftJson.isNullOrEmpty()) {
                    try {
                        val shiftObj = JSONObject(activeShiftJson)
                        isShiftOpen = true
                        todayOrders = shiftObj.optInt("ordersCount", 0)
                        activeOrderPrice = shiftObj.optDouble("orderPrice", orderPrice)
                    } catch (_: Exception) {}
                }

                var isHolidayToday = false
                var isShiftFinishedToday = false
                var finishedTodayOrders = 0

                var monthOrders = 0
                var monthGross = 0.0
                var monthRecordedDays = 0

                try {
                    val arr = JSONArray(recordsJson)
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        val dateStr = obj.getString("date")
                        val year = dateStr.substring(0, 4).toInt()
                        val month = dateStr.substring(5, 7).toInt()

                        val isWorkDay = obj.optBoolean("isWorkDay", true)
                        val orders = obj.optInt("ordersCount", 0)
                        val price = obj.optDouble("orderPrice", orderPrice)

                        if (dateStr.startsWith(todayStr)) {
                            if (!isWorkDay) {
                                isHolidayToday = true
                            } else {
                                isShiftFinishedToday = true
                                finishedTodayOrders = orders
                            }
                        }

                        if (year == curYear && month == curMonth) {
                            if (isWorkDay) {
                                monthOrders += orders
                                monthGross += orders * price
                            }
                            monthRecordedDays += 1
                        }
                    }
                } catch (_: Exception) {}

                var monthGas = 0.0
                try {
                    val gasArr = JSONArray(gasJson)
                    for (i in 0 until gasArr.length()) {
                        val obj = gasArr.getJSONObject(i)
                        val dateStr = obj.getString("date")
                        val year = dateStr.substring(0, 4).toInt()
                        val month = dateStr.substring(5, 7).toInt()
                        if (year == curYear && month == curMonth) {
                            monthGas += obj.optDouble("amount", 0.0)
                        }
                    }
                } catch (_: Exception) {}

                var monthOther = 0.0
                try {
                    val otherArr = JSONArray(otherJson)
                    for (i in 0 until otherArr.length()) {
                        val obj = otherArr.getJSONObject(i)
                        val dateStr = obj.getString("date")
                        val year = dateStr.substring(0, 4).toInt()
                        val month = dateStr.substring(5, 7).toInt()
                        if (year == curYear && month == curMonth) {
                            monthOther += obj.optDouble("amount", 0.0)
                        }
                    }
                } catch (_: Exception) {}

                val effectiveMonthOrders = if (isShiftOpen) (monthOrders + todayOrders) else monthOrders
                val effectiveMonthGross = if (isShiftOpen) (monthGross + (todayOrders * activeOrderPrice)) else monthGross
                val netIncome = effectiveMonthGross - (monthRecordedDays * dailyRent) - monthGas - monthOther

                val monthNames = arrayOf(
                    "", "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
                    "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
                )

                val views = RemoteViews(context.packageName, R.layout.order_widget)

                val displayOrders: Int
                val expectedIncome: Double

                when {
                    isShiftOpen -> {
                        displayOrders = todayOrders
                        expectedIncome = todayOrders * activeOrderPrice
                        views.setTextViewText(R.id.widget_status_badge, "الوردية مفتوحة 🟢")
                        views.setTextColor(R.id.widget_status_badge, 0xFF2FBE77.toInt())
                        views.setInt(R.id.widget_status_badge, "setBackgroundResource", R.drawable.widget_badge_active)
                        val progressPercent = if (dailyTarget > 0) ((todayOrders.toDouble() / dailyTarget) * 100).toInt().coerceIn(0, 100) else 0
                        views.setTextViewText(R.id.widget_today_target_sub, "من $dailyTarget طلب اليوم ($progressPercent%)")
                        views.setProgressBar(R.id.widget_progress_bar, 100, progressPercent, false)
                    }
                    isHolidayToday -> {
                        displayOrders = 0
                        expectedIncome = 0.0
                        views.setTextViewText(R.id.widget_status_badge, "اليوم إجازة 🌴")
                        views.setTextColor(R.id.widget_status_badge, 0xFFA29BFE.toInt())
                        views.setInt(R.id.widget_status_badge, "setBackgroundResource", R.drawable.widget_badge_closed)
                        views.setTextViewText(R.id.widget_today_target_sub, "يوم راحة مستحق للكابتن")
                        views.setProgressBar(R.id.widget_progress_bar, 100, 0, false)
                    }
                    isShiftFinishedToday -> {
                        displayOrders = finishedTodayOrders
                        expectedIncome = finishedTodayOrders * orderPrice
                        views.setTextViewText(R.id.widget_status_badge, "تم حفظ الوردية ✓")
                        views.setTextColor(R.id.widget_status_badge, 0xFFD4AF37.toInt())
                        views.setInt(R.id.widget_status_badge, "setBackgroundResource", R.drawable.widget_badge_closed)
                        val progressPercent = if (dailyTarget > 0) ((finishedTodayOrders.toDouble() / dailyTarget) * 100).toInt().coerceIn(0, 100) else 0
                        views.setTextViewText(R.id.widget_today_target_sub, "اكتملت وردية اليوم ($progressPercent%)")
                        views.setProgressBar(R.id.widget_progress_bar, 100, progressPercent, false)
                    }
                    else -> {
                        displayOrders = 0
                        expectedIncome = 0.0
                        views.setTextViewText(R.id.widget_status_badge, "الوردية مغلقة ⚪")
                        views.setTextColor(R.id.widget_status_badge, 0xFFB0BEC5.toInt())
                        views.setInt(R.id.widget_status_badge, "setBackgroundResource", R.drawable.widget_badge_closed)
                        views.setTextViewText(R.id.widget_today_target_sub, "التارجت اليومي: $dailyTarget طلب")
                        views.setProgressBar(R.id.widget_progress_bar, 100, 0, false)
                    }
                }

                views.setTextViewText(R.id.widget_today_orders, "$displayOrders")
                views.setTextViewText(R.id.widget_today_income, "${String.format("%.1f", expectedIncome)} ر.س")

                views.setTextViewText(R.id.widget_month_name_label, "صافي ${monthNames[curMonth]}")
                views.setTextViewText(R.id.widget_month_orders, "$effectiveMonthOrders طلب")

                val netFormatted = "${if (netIncome >= 0) "+" else ""}${netIncome.toInt()} ر.س"
                views.setTextViewText(R.id.widget_month_net, netFormatted)
                views.setTextColor(R.id.widget_month_net, if (netIncome >= 0) 0xFF2FBE77.toInt() else 0xFFE0555F.toInt())

                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    val pendingIntent = android.app.PendingIntent.getActivity(
                        context, 0, launchIntent,
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (_: Exception) {
                try {
                    val fallbackViews = RemoteViews(context.packageName, R.layout.order_widget)
                    appWidgetManager.updateAppWidget(appWidgetId, fallbackViews)
                } catch (_: Exception) {}
            }
        }
    }
}
