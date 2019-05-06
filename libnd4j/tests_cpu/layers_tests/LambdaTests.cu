/*******************************************************************************
 * Copyright (c) 2015-2018 Skymind, Inc.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Apache License, Version 2.0 which is available at
 * https://www.apache.org/licenses/LICENSE-2.0.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

//
// @author raver119@gmail.com
//

#include "testlayers.h"
#include <array/ExtraArguments.h>
#include <array>
#include <cuda.h>
#include <cuda_runtime.h>

using namespace nd4j;

class LambdaTests : public testing::Test {
public:

    LambdaTests() {
        printf("\n");
        fflush(stdout);
    }
};

template <typename Lambda>
__global__ void runLambda(double *input, double *output, Nd4jLong length, Lambda lambda) {
    auto tid = blockIdx.x * blockDim.x + threadIdx.x;
    for (Nd4jLong e = tid; e < length; e += gridDim.x * blockDim.x) {
        output[e] = lambda(input[e]);
    }
}

void launcher(cudaStream_t *stream, double *input, double *output, Nd4jLong length) {
    //auto f = [] __host__ __device__ (double x) -> double {
    //        return x + 1.;
    //};
    auto f = LAMBDA_D(x) {
        return x+1.;
    };


    runLambda<<<128, 128, 128, *stream>>>(input, output, length, f);
}


TEST_F(LambdaTests, test_basic_1) {
    auto x = NDArrayFactory::create<double>('c', {5});
    auto e = NDArrayFactory::create<double>('c', {5}, {1., 1., 1., 1., 1.});



    //x.applyLambda<double>(f, nullptr);
    launcher(LaunchContext::defaultContext()->getCudaStream(), (double *)x.specialBuffer(), (double *)x.specialBuffer(), x.lengthOf());
    auto res = cudaStreamSynchronize(*LaunchContext::defaultContext()->getCudaStream());
    ASSERT_EQ(0, res);

    ASSERT_EQ(e, x);

    x.printIndexedBuffer("x");
}

void test(NDArray &x) {
    auto f = LAMBDA_D(x) {
        return x+1.;
    };

    x.applyLambda(f, &x);
}

template <typename T>
void test2(NDArray &x) {
    auto f = LAMBDA_T(x) {
        return x+1.;
    };

    x.applyLambda(f, &x);
}

void testPairwise(NDArray &x, NDArray &y) {
    auto f = LAMBDA_DD(x, y) {
        return x + y +1.;
    };

    x.applyPairwiseLambda(&y, f, &x);
}

void testTriplewise(NDArray &i, NDArray &j, NDArray &k) {
    auto f = LAMBDA_DDD(i, j, k) {
        return i + j + k + 2.;
    };

    i.applyTriplewiseLambda(&j, &k, f, &i);
}

void testIndexed(NDArray &x) {
    auto f = ILAMBDA_D(x) {
        return _idx + 1.;
    };

    x.applyIndexedLambda(f, &x);
}

TEST_F(LambdaTests, test_basic_2) {
    auto x = NDArrayFactory::create<double>('c', {5});
    auto e = NDArrayFactory::create<double>('c', {5}, {1., 1., 1., 1., 1.});

    test(x);

    x.printIndexedBuffer("x");
    ASSERT_EQ(e, x);
}

TEST_F(LambdaTests, test_basic_3) {
    auto x = NDArrayFactory::create<float>('c', {5});
    auto e = NDArrayFactory::create<float>('c', {5}, {1.f, 1.f, 1.f, 1.f, 1.f});

    test(x);

    x.printIndexedBuffer("x");
    ASSERT_EQ(e, x);
}

TEST_F(LambdaTests, test_basic_4) {
    auto x = NDArrayFactory::create<float>('c', {5});
    auto e = NDArrayFactory::create<float>('c', {5}, {1.f, 1.f, 1.f, 1.f, 1.f});

    test2<float>(x);

    x.printIndexedBuffer("x");
    ASSERT_EQ(e, x);
}

TEST_F(LambdaTests, test_basic_5) {
    auto x = NDArrayFactory::create<double>('c', {5}, {1., 1., 1., 1., 1.});
    auto y = NDArrayFactory::create<double>('c', {5}, {2., 2., 2., 2., 2.});
    auto e = NDArrayFactory::create<double>('c', {5}, {4., 4., 4., 4., 4.});

    testPairwise(x, y);

    x.printIndexedBuffer("x");
    ASSERT_EQ(e, x);
}

TEST_F(LambdaTests, test_basic_6) {
    auto x = NDArrayFactory::create<double>('c', {5});
    auto e = NDArrayFactory::create<double>('c', {5}, {1., 2., 3., 4., 5.});

    testIndexed(x);

    x.printIndexedBuffer("x");
    ASSERT_EQ(e, x);
}

TEST_F(LambdaTests, test_basic_7) {
    auto w = NDArrayFactory::create<double>('c', {5}, {0., 0., 0., 0., 0.});
    auto x = NDArrayFactory::create<double>('c', {5}, {1., 1., 1., 1., 1.});
    auto y = NDArrayFactory::create<double>('c', {5}, {2., 2., 2., 2., 2.});
    auto e = NDArrayFactory::create<double>('c', {5}, {5., 5., 5., 5., 5.});

    testTriplewise(w, x, y);

    w.printIndexedBuffer("w");
    ASSERT_EQ(e, w);
}
