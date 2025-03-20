package com.example.sign_in_life;

import static android.content.ContentValues.TAG;

import static io.flutter.util.PathUtils.getFilesDir;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.location.Location;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Log;
import android.util.Pair;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;

import com.amap.api.maps.AMap;
import com.amap.api.maps.AMapOptions;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.MapView;
import com.amap.api.maps.MapsInitializer;
import com.amap.api.maps.model.CameraPosition;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.LatLngBounds;
import com.amap.api.maps.model.MyLocationStyle;
import com.amap.api.maps.model.PolylineOptions;
import com.amap.api.maps.utils.SpatialRelationUtil;
import com.amap.api.maps.utils.overlay.SmoothMoveMarker;
import com.amap.api.trace.LBSTraceClient;
import com.example.sign_in_life.listener.MyTraceStatusListener;
import com.example.sign_in_life.utils.PositionUtil;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

import java.io.File;
import java.io.FileInputStream;
import java.util.List;
import java.util.Map;

class NativeView implements PlatformView, MethodChannel.MethodCallHandler {

    MapView mMapView = null;
    AMap aMap = null;

    LBSTraceClient lbsTraceClient = null;

    MyTraceStatusListener traceListener = null;

    private boolean recording = false;

    private boolean initPosition = false;

    private MethodChannel methodChannel;

    private Context context;

    NativeView(@NonNull Context context, BinaryMessenger messenger, int id, @Nullable Map<String, Object> creationParams) {
        this.context = context;
        methodChannel = new MethodChannel(messenger, "com.example.sign_in_life/native_view");
        methodChannel.setMethodCallHandler(this);
        MapsInitializer.updatePrivacyShow(context, true, true);
        MapsInitializer.updatePrivacyAgree(context, true);
        mMapView = new MapView(context, new AMapOptions());
        aMap = mMapView.getMap();
        aMap.moveCamera(CameraUpdateFactory.zoomTo(18));
        mMapView.onCreate(null);
        startLocation();
        //在activity执行onCreate时执行mMapView.onCreate(savedInstanceState)，创建地图
        // startLocation();
    }

    public void startLocation() {
        if (aMap == null) {
            Log.d(TAG, "startLocation: aMap is null");
            aMap = mMapView.getMap();
        }
        Log.d(TAG, "startLocation");
        aMap.setMapType(AMap.MAP_TYPE_NORMAL);
        MyLocationStyle myLocationStyle;
        myLocationStyle = new MyLocationStyle();//初始化定位蓝点样式类myLocationStyle.myLocationType(MyLocationStyle.LOCATION_TYPE_LOCATION_ROTATE);//连续定位、且将视角移动到地图中心点，定位点依照设备方向旋转，并且会跟随设备移动。（1秒1次定位）如果不设置myLocationType，默认也会执行此种模式。
        myLocationStyle.myLocationType(MyLocationStyle.LOCATION_TYPE_FOLLOW_NO_CENTER);
        myLocationStyle.interval(2000); //设置连续定位模式下的定位间隔，只在连续定位模式下生效，单次定位模式下不会生效。单位为毫秒。
        aMap.setMyLocationStyle(myLocationStyle);//设置定位蓝点的Style
//                        aMap.getUiSettings().setMyLocationButtonEnabled(true);//设置默认定位按钮是否显示，非必需设置。
        aMap.setMyLocationEnabled(true);// 设置为true表示启动显示定位蓝点，false表示隐藏定位蓝点并不进行定位，默认是false。
        aMap.addOnMyLocationChangeListener(this::onMyLocationChange);
    }

    @NonNull
    @Override
    public View getView() {
        return mMapView;
    }

    @Override
    public void dispose() {
        mMapView.onDestroy();
    }

    private Location oldLocation = null;

    public void onMyLocationChange(Location location) {
        //从location对象中获取经纬度信息，地址描述信息，建议拿到位置之后调用逆地理编码接口获取（获取地址描述数据章节有介绍）
        Log.d(TAG, "onMyLocationChange: " + location);

        if (location.getLatitude() == 0 && location.getLongitude() == 0) {
            return;
        }
        if (oldLocation != null) {
            // 距离超过500米
            if (PositionUtil.getDistance(oldLocation.getLongitude(), oldLocation.getLatitude(), location.getLongitude(), location.getLatitude()) > 500) {
                aMap.moveCamera(CameraUpdateFactory.newCameraPosition(new CameraPosition(new LatLng(location.getLatitude(), location.getLongitude()), 18, 0, 0)));
            }
        }
        oldLocation = location;
        if (!initPosition) {
            initPosition = true;
            aMap.moveCamera(CameraUpdateFactory.newCameraPosition(new CameraPosition(new LatLng(location.getLatitude(), location.getLongitude()), 18, 0, 0)));
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("startLocation")) {
            startLocation();
            result.success(null);
        } else if (call.method.equals("startRecording")) {
            try {
                startRecording();
            } catch (Exception e) {
                result.success(null);
            }
            result.success(null);
        } else if (call.method.equals("stopRecording")) {
            stopRecording();
            result.success(null);
        } else if (call.method.equals("playbackRecording")) {
            playbackRecording();
            result.success(null);
        }
        else {
            result.notImplemented();
        }
    }

    public void startRecording() {
        if (!recording) {
            recording = true;
            Toast.makeText(context, "开始记录轨迹", Toast.LENGTH_SHORT).show();
            try {
                lbsTraceClient = LBSTraceClient.getInstance(context);
                traceListener = new MyTraceStatusListener(aMap, context);
                lbsTraceClient.startTrace(traceListener); //开始采集,需要传入一个状态回调监听。
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
    }

    public void stopRecording() {
        if (recording) {
            recording = false;
            Toast.makeText(context, "停止记录轨迹", Toast.LENGTH_SHORT).show();
            lbsTraceClient.stopTrace(); //停止采集
            traceListener.saveRawTrack();
            traceListener.saveCorrectedTrack();
        }
    }

    public void playbackRecording() {
            File file = new File(getFilesDir(context), "corrected_track_data.json");
            if (file.exists()) {
                try {
                    FileInputStream fis = new FileInputStream(file);
                    byte[] buffer = new byte[(int) file.length()];
                    fis.read(buffer);
                    fis.close();
                    String content = new String(buffer);
                    Log.d(TAG, content);
                    List<LatLng> rectifications = new Gson().fromJson(content, new TypeToken<List<LatLng>>() {
                    }.getType());

                    aMap.addPolyline(new PolylineOptions().
                            addAll(rectifications).width(10).color(Color.argb(255, 1, 1, 255)));


// 获取轨迹坐标点
                    LatLngBounds bounds = new LatLngBounds(rectifications.get(0), rectifications.get(rectifications.size() - 2));
                    aMap.animateCamera(CameraUpdateFactory.newLatLngBounds(bounds, 50));

                    SmoothMoveMarker smoothMarker = new SmoothMoveMarker(aMap);
// 设置滑动的图标
//                    smoothMarker.setDescriptor(BitmapDescriptorFactory.fromResource(R.drawable.ic_launcher_foreground));

                    LatLng drivePoint = rectifications.get(0);
                    Pair<Integer, LatLng> pair = SpatialRelationUtil.calShortestDistancePoint(rectifications, drivePoint);
                    rectifications.set(pair.first, drivePoint);
                    List<LatLng> subList = rectifications.subList(pair.first, rectifications.size());

// 设置滑动的轨迹左边点
                    smoothMarker.setPoints(subList);
// 设置滑动的总时间
                    smoothMarker.setTotalDuration(10);
// 开始滑动
                    smoothMarker.startSmoothMove();



                    Log.d(TAG, content);
                } catch (Exception e) {
                    Log.e(TAG, "Error reading file", e);
                }
            } else {
                Toast.makeText(context, "没有找到轨迹数据", Toast.LENGTH_SHORT).show();
            }
    }


}