package com.example.sign_in_life.listener;

import static android.content.ContentValues.TAG;
import static com.autonavi.base.amap.mapcore.tools.GLFileUtil.getFilesDir;

import android.content.Context;
import android.util.Log;
import android.widget.Toast;

import com.amap.api.maps.model.LatLng;
import com.amap.api.trace.TraceListener;
import com.google.gson.Gson;

import java.io.File;
import java.io.FileOutputStream;
import java.util.List;

public class MyTraceListener implements TraceListener {

    private final Context context;

    public MyTraceListener(Context context) {
        this.context = context;
    }

    @Override
    public void onRequestFailed(int lineID, String errorInfo) {
        Log.d(TAG, "onRequestFailed: " + errorInfo);
        Toast.makeText(context, "onRequestFailed", Toast.LENGTH_SHORT).show();
    }

    @Override
    public void onTraceProcessing(int lineID, int i1, List<LatLng> list) {

    }

    @Override
    public void onFinished(int lineID, List<LatLng> linePoints, int distance, int waitingTime) {
        saveCorrectedTrack(linePoints);
        Toast.makeText(context, "onFinished", Toast.LENGTH_SHORT).show();
    }

    public void saveCorrectedTrack(List<LatLng> linePoints) {
        Gson gson = new Gson();
        String json = gson.toJson(linePoints);
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
