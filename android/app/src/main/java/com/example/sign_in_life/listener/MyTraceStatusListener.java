package com.example.sign_in_life.listener;

import static android.content.ContentValues.TAG;
import static com.autonavi.base.amap.mapcore.tools.GLFileUtil.getFilesDir;

import android.content.Context;
import android.graphics.Color;
import android.os.Build;
import android.util.Log;

import com.amap.api.maps.AMap;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.PolylineOptions;
import com.amap.api.trace.TraceLocation;
import com.amap.api.trace.TraceStatusListener;
import com.google.gson.Gson;

import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.List;

public class MyTraceStatusListener implements TraceStatusListener {

    private final AMap aMap;
    private final Context context;

    private List<TraceLocation> locations = new ArrayList<>();

    private List<LatLng> rectifications = new ArrayList<>();

    public MyTraceStatusListener(AMap aMap, Context context) {
        this.aMap = aMap;
        this.context = context;
    }

    @Override
    public void onTraceStatus(List<TraceLocation> locations, List<LatLng> rectifications, String errorInfo) {
        Log.d(TAG, "locations size: " + locations.size());
        Log.d(TAG, "rectifications size: " + rectifications.size());
        Log.d(TAG, "errorInfo: " + errorInfo);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            rectifications.forEach(latLng -> {
                Log.d(TAG, "latLng: " + latLng);
            });
        }

        this.locations.addAll(locations);
        this.rectifications.addAll(rectifications);

//        List<LatLng> latLngs = new ArrayList<LatLng>();
//        latLngs.add(new LatLng(39.999391,116.135972));
//        latLngs.add(new LatLng(39.898323,116.057694));
//        latLngs.add(new LatLng(39.900430,116.265061));
//        latLngs.add(new LatLng(39.955192,116.140092));
        aMap.addPolyline(new PolylineOptions().
                addAll(rectifications).width(10).color(Color.argb(255, 1, 1, 1)));
    }

    // Save the raw track and corrected track data to local files
    public void saveRawTrack() {
        StringBuilder sb = new StringBuilder();
        for (TraceLocation loc : locations) {
            sb.append(loc.toString()).append("\n");
        }
        writeToFile("raw_track_data.txt", sb.toString());
    }

    public void saveCorrectedTrack() {
        Gson gson = new Gson();
        String json = gson.toJson(rectifications);
        writeToFile("corrected_track_data.json", json);
    }

    private void writeToFile(String fileName, String data) {
        File file = new File(getFilesDir(context), fileName);
        try {
            FileOutputStream fos = new FileOutputStream(file);
            fos.write(data.getBytes());
            fos.close();
        } catch (Exception e) {
            Log.e(TAG, "Error saving file: " + fileName, e);
        }
    }
}
