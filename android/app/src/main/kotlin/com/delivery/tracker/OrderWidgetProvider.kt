package com.delivery.tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class OrderWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_INCREMENT -> handleIncrement(context)
            ACTION_DECREMENT -> handleDecrement(context)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    private fun handleIncrement(context: Context) {
        val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isShiftOpenPref = getSafeBoolean(prefs, "flutter.shiftOpen", false)
        val activeShiftJson = prefs.getString("flutter.activeShift", null)
        val isShiftOpen = isShiftOpenPref || !activeShiftJson.isNullOrEmpty()

        if (!isShiftOpen) {
            // فتح التطبيق إذا كانت الوردية مغلقة
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            if (launchIntent != null) {
                context.startActivity(launchIntent)
            }
            return
        }

        var newCount = 1

        if (!activeShiftJson.isNullOrEmpty()) {
            try {
                val shiftObj = JSONObject(activeShiftJson)
                val current = shiftObj.optInt("ordersCount", 0)
                newCount = current + 1
                shiftObj.put("ordersCount", newCount)
                prefs.edit()
                    .putString("flutter.activeShift", shiftObj.toString())
                    .putLong("flutter.todayOrders", newCount.toLong())
                    .apply()
            } catch (_: Exception) {
                prefs.edit().putLong("flutter.todayOrders", newCount.toLong()).apply()
            }
        } else {
            val current = getSafeInt(prefs, "flutter.todayOrders", 0)
            newCount = current + 1
            prefs.edit().putLong("flutter.todayOrders", newCount.toLong()).apply()
        }

        updateAllWidgets(context)
    }

    private fun handleDecrement(context: Context) {
        val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isShiftOpenPref = getSafeBoolean(prefs, "flutter.shiftOpen", false)
        val activeShiftJson = prefs.getString("flutter.activeShift", null)
        val isShiftOpen = isShiftOpenPref || !activeShiftJson.isNullOrEmpty()

        if (!isShiftOpen) return

        if (!activeShiftJson.isNullOrEmpty()) {
            try {
                val shiftObj = JSONObject(activeShiftJson)
                val current = shiftObj.optInt("ordersCount", 0)
                if (current > 0) {
                    val newCount = current - 1
                    shiftObj.put("ordersCount", newCount)
                    prefs.edit()
                        .putString("flutter.activeShift", shiftObj.toString())
                        .putLong("flutter.todayOrders", newCount.toLong())
                        .apply()
                    updateAllWidgets(context)
                }
            } catch (_: Exception) {}
        } else {
            val current = getSafeInt(prefs, "flutter.todayOrders", 0)
            if (current > 0) {
                val newCount = current - 1
                prefs.edit().putLong("flutter.todayOrders", newCount.toLong()).apply()
                updateAllWidgets(context)
            }
        }
    }

    companion object {
        const val ACTION_INCREMENT = "com.delivery.tracker.ACTION_INCREMENT"
        const val ACTION_DECREMENT = "com.delivery.tracker.ACTION_DECREMENT"

        private fun getSafeBoolean(prefs: SharedPreferences, key: String, defaultVal: Boolean): Boolean {
            return try {
                prefs.getBoolean(key, defaultVal)
            } catch (_: Exception) {
                defaultVal
            }
        }

        private fun getSafeInt(prefs: SharedPreferences, key: String, defaultVal: Int): Int {
            if (!prefs.contains(key)) return defaultVal
            return try {
                prefs.getInt(key, defaultVal)
            } catch (_: Exception) {
                try {
                    prefs.getLong(key, defaultVal.toLong()).toInt()
                } catch (_: Exception) {
                    try {
                        prefs.getString(key, null)?.toIntOrNull() ?: defaultVal
                    } catch (_: Exception) {
                        defaultVal
                    }
                }
            }
        }

        private fun getSafeDouble(prefs: SharedPreferences, key: String, defaultVal: Double): Double {
            if (!prefs.contains(key)) return defaultVal
            return try {
                prefs.getFloat(key, defaultVal.toFloat()).toDouble()
            } catch (_: Exception) {
                try {
                    prefs.getLong(key, defaultVal.toLong()).toDouble()
                } catch (_: Exception) {
                    try {
                        prefs.getInt(key, defaultVal.toInt()).toDouble()
                    } catch (_: Exception) {
                        try {
                            val str = prefs.getString(key, null)
                            if (str != null) {
                                val cleaned = if (str.startsWith("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu")) {
                                    str.removePrefix("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu")
                                } else {
                                    str
                                }
                                cleaned.toDoubleOrNull() ?: defaultVal
                            } else {
                                defaultVal
                            }
                        } catch (_: Exception) {
                            defaultVal
                        }
                    }
                }
            }
        }

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
                val isShiftOpenPref = getSafeBoolean(prefs, "flutter.shiftOpen", false)

                val orderPrice = getSafeDouble(prefs, "flutter.orderPrice", 10.0)
                val dailyRent = getSafeDouble(prefs, "flutter.dailyRent", 40.0)
                val dailyTarget = getSafeInt(prefs, "flutter.dailyTarget", 16)

                val cal = Calendar.getInstance()
                val curYear = cal.get(Calendar.YEAR)
                val curMonth = cal.get(Calendar.MONTH) + 1
                val curDay = cal.get(Calendar.DAY_OF_MONTH)
                val todayStr = String.format("%04d-%02d-%02d", curYear, curMonth, curDay)

                var isShiftOpen = false
                var todayOrders = 0
                var activeOrderPrice = orderPrice

                if (isShiftOpenPref || !activeShiftJson.isNullOrEmpty()) {
                    if (!activeShiftJson.isNullOrEmpty()) {
                        try {
                            val shiftObj = JSONObject(activeShiftJson)
                            isShiftOpen = true
                            todayOrders = shiftObj.optInt("ordersCount", getSafeInt(prefs, "flutter.todayOrders", 0))
                            activeOrderPrice = shiftObj.optDouble("orderPrice", orderPrice)
                        } catch (_: Exception) {
                            isShiftOpen = isShiftOpenPref
                            todayOrders = getSafeInt(prefs, "flutter.todayOrders", 0)
                        }
                    } else {
                        isShiftOpen = isShiftOpenPref
                        todayOrders = getSafeInt(prefs, "flutter.todayOrders", 0)
                    }
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

                val views = RemoteViews(context.packageName, R.layout.order_widget)

                val displayOrders: Int
                val expectedIncome: Double

                when {
                    isShiftOpen -> {
                        displayOrders = todayOrders
                        expectedIncome = todayOrders * activeOrderPrice
                        views.setTextViewText(R.id.tv_bento_shift_status, "الوردية شغالة ●")
                        views.setTextColor(R.id.tv_bento_shift_status, 0xFF34D399.toInt())
                        views.setInt(R.id.tv_bento_shift_status, "setBackgroundResource", R.drawable.bg_bento_shift_pill)
                    }
                    isHolidayToday -> {
                        displayOrders = 0
                        expectedIncome = 0.0
                        views.setTextViewText(R.id.tv_bento_shift_status, "يوم إجازة 🌴")
                        views.setTextColor(R.id.tv_bento_shift_status, 0xFFA78BFA.toInt())
                        views.setInt(R.id.tv_bento_shift_status, "setBackgroundResource", R.drawable.bg_bento_shift_pill_closed)
                    }
                    isShiftFinishedToday -> {
                        displayOrders = finishedTodayOrders
                        expectedIncome = finishedTodayOrders * orderPrice
                        views.setTextViewText(R.id.tv_bento_shift_status, "اكتملت الوردية ✓")
                        views.setTextColor(R.id.tv_bento_shift_status, 0xFFFBBF24.toInt())
                        views.setInt(R.id.tv_bento_shift_status, "setBackgroundResource", R.drawable.bg_bento_shift_pill_closed)
                    }
                    else -> {
                        displayOrders = 0
                        expectedIncome = 0.0
                        views.setTextViewText(R.id.tv_bento_shift_status, "الوردية مغلقة ⚪")
                        views.setTextColor(R.id.tv_bento_shift_status, 0xFF9CA3AF.toInt())
                        views.setInt(R.id.tv_bento_shift_status, "setBackgroundResource", R.drawable.bg_bento_shift_pill_closed)
                    }
                }

                val progressPercent = if (dailyTarget > 0) ((displayOrders.toDouble() / dailyTarget) * 100).toInt().coerceIn(0, 100) else 0

                // 1. بطاقة حلقة الإنجاز
                views.setTextViewText(R.id.tv_bento_orders_count, "$displayOrders")
                views.setTextViewText(R.id.tv_bento_progress_percent, "$progressPercent%")
                views.setTextViewText(R.id.tv_bento_target_goal, "الهدف: $dailyTarget")
                views.setProgressBar(R.id.pb_bento_ring, 100, progressPercent, false)

                // 2. بطاقة الأرباح والوفر
                views.setTextViewText(R.id.tv_bento_today_income, "${String.format("%.1f", expectedIncome)} ر.س")
                val netFormatted = "${if (netIncome >= 0) "+" else ""}${String.format("%,d", netIncome.toInt())} ر.س"
                views.setTextViewText(R.id.tv_bento_total_savings, netFormatted)
                views.setTextColor(R.id.tv_bento_total_savings, if (netIncome >= 0) 0xFF10B981.toInt() else 0xFFF87171.toInt())

                // 3. أزرار التسجيل السريع
                val plusIntent = Intent(context, OrderWidgetProvider::class.java).apply {
                    action = ACTION_INCREMENT
                }
                val plusPending = PendingIntent.getBroadcast(
                    context, 101, plusIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_bento_increment, plusPending)

                val minusIntent = Intent(context, OrderWidgetProvider::class.java).apply {
                    action = ACTION_DECREMENT
                }
                val minusPending = PendingIntent.getBroadcast(
                    context, 102, minusIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.btn_bento_decrement, minusPending)

                // 4. فتح التطبيق عند النقر
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    val appPending = PendingIntent.getActivity(
                        context, 100, launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.bento_widget_root, appPending)
                    views.setOnClickPendingIntent(R.id.bento_tile_ring, appPending)
                    views.setOnClickPendingIntent(R.id.bento_tile_header, appPending)
                    views.setOnClickPendingIntent(R.id.bento_tile_earnings, appPending)
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
