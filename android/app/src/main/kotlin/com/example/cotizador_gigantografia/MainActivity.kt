package com.example.cotizador_gigantografia

import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.graphics.Color
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Eliminar configuración personalizada de transparencia y flags
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Configurar el engine para renderizar inmediatamente
        flutterEngine.renderer.let { renderer ->
            renderer.setSemanticsEnabled(false)
        }
    }
}
