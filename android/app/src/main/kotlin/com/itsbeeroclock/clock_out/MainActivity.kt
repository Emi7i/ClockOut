package com.itsbeeroclock.clock_out

import android.content.Context
import androidx.multidex.MultiDex
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun attachBaseContext(newBase: Context) {
        super.attachBaseContext(newBase)
        MultiDex.install(this)
    }
}
