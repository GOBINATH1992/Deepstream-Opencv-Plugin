/*
 * SPDX-FileCopyrightText: Copyright (c) 2021-2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#ifndef _GST_NV_VIDEO_TEST_SRC_H_
#define _GST_NV_VIDEO_TEST_SRC_H_

#include <stdio.h>
#include <gst/gst.h>
#include <gst/base/base.h>
#include <gst/video/video.h>
#include <gst/video/gstvideometa.h>
#include <gst/video/gstvideopool.h>

#include <nvbufsurface.h>

/* Open CV headers */
#pragma GCC diagnostic push
#if __GNUC__ >= 8
#pragma GCC diagnostic ignored "-Wclass-memaccess"
#endif
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/videoio.hpp"
#include "opencv2/core/cuda.hpp"
#include "opencv2/cudaimgproc.hpp"
#include "opencv2/cudacodec.hpp"
#include "opencv2/cudaimgproc.hpp"

G_BEGIN_DECLS

#define GST_TYPE_NV_VIDEO_TEST_SRC          (gst_nv_video_test_src_get_type())
#define GST_NV_VIDEO_TEST_SRC(obj)          (G_TYPE_CHECK_INSTANCE_CAST((obj), GST_TYPE_NV_VIDEO_TEST_SRC, GstNvVideoTestSrc))
#define GST_NV_VIDEO_TEST_SRC_CLASS(klass)  (G_TYPE_CHECK_CLASS_CAST((klass), GST_TYPE_NV_VIDEO_TEST_SRC, GstNvVideoTestSrcClass))
#define GST_IS_NV_VIDEO_TEST_SRC(obj)       (G_TYPE_CHECK_INSTANCE_TYPE((obj), GST_TYPE_NV_VIDEO_TEST_SRC))
#define GST_IS_NV_VIDEO_TEST_SRC_CLASS(obj) (G_TYPE_CHECK_CLASS_TYPE((klass), GST_TYPE_NV_VIDEO_TEST_SRC))

typedef enum {
    GST_NV_VIDEO_TEST_SRC_SMPTE,
    GST_NV_VIDEO_TEST_SRC_MANDELBROT,
    GST_NV_VIDEO_TEST_SRC_GRADIENT
} GstNvVideoTestSrcPattern;

typedef enum {
    GST_NV_VIDEO_TEST_SRC_FRAMES,
    GST_NV_VIDEO_TEST_SRC_WALL_TIME,
    GST_NV_VIDEO_TEST_SRC_RUNNING_TIME
} GstNvVideoTestSrcAnimationMode;

typedef struct _GstNvVideoTestSrc GstNvVideoTestSrc;
typedef struct _GstNvVideoTestSrcClass GstNvVideoTestSrcClass;

struct _GstNvVideoTestSrc {
    GstPushSrc parent;

    // Plugin parameters.
    GstNvVideoTestSrcPattern pattern;
    GstNvVideoTestSrcAnimationMode animation_mode;
    guint gpu_id;
    NvBufSurfaceMemType memtype;
    
    /** Processing Queue and related synchronization structures. */
 
    /** Gmutex lock for against shared access in threads**/
    GMutex process_lock;
  
    /** Queue to send data to output thread for processing**/
    GQueue *process_queue;
  
    /** Gcondition for process queue**/
    GCond process_cond;
    
    /**Queue to receive processed data from output thread **/
    GQueue *buf_queue;
  
    /** Gcondition for buf queue **/
    GCond buf_cond;
  
    /** Output thread. */
    GThread *process_thread;

    /** Boolean to signal output thread to stop. */
    gboolean stop;
    
    // Stream details set during caps negotiation.
    GstCaps *caps;
    GstVideoInfo info;

    // Runtime state.
    GstClockTime running_time;
    gint64 filled_frames;
    guint w;
    guint h;
    guint fps;
    // File read related
    gchar *filename; 
    cv::VideoCapture  *cam_handle ;                          /* filename */
    //FILE *file_handle;
    guint64 read_position;                    /* position of fd */
    //NvBufSurface *file_read_surface = NULL;   /* surface for file read */
    gboolean file_loop;

    // Jitter related
    guint max_jitter = 0;        // max jitter in ms
    GstClockTime last_buffer_start_timestamp = 0;
    void *p_fixed_jitter_list = NULL;
};

/**
 * Holds information about the batch of frames to be inferred.
 */
typedef struct
{
  
  /** Pointer to the input GstBuffer. */
  GstBuffer *inbuf = nullptr;
  /** Batch number of the input batch. */
  gulong inbuf_batch_num = 0;
  /** Boolean indicating that the output thread should only push the buffer to
   * downstream element. If set to true, a corresponding batch has not been
   * queued at the input of NvDsExampleContext and hence dequeuing of output is
   * not required. */
  gboolean push_buffer = FALSE;
  /** Boolean marking this batch as an event marker. This is only used for
   * synchronization. The output loop does not process on the batch.
   */
  

  /** OpenCV mat containing RGB data */
  cv::Mat * cvmat;

} GstDsExampleBatch;

struct _GstNvVideoTestSrcClass {
    GstPushSrcClass parent_class;
};

GType gst_nv_video_test_src_get_type(void);

G_END_DECLS

#endif
