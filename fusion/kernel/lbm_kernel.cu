
__global__ void ori_lbm( float* srcGrid, float* dstGrid, int iteration)  {
    for (int loop = 0; loop < iteration; loop++) {
        //Using some predefined macros here.  Consider this the declaration 
        //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

        SWEEP_VAR
        SWEEP_X = threadIdx.x;
        SWEEP_Y = blockIdx.x;
        SWEEP_Z = blockIdx.y;

        float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
        float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
        float tempSB, tempET, tempEB, tempWT, tempWB ;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}


__global__ void ptb_lbm( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z, int iteration) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    unsigned int block_pos = blockIdx.x;
    int thread_id_x = threadIdx.x % block_dimension_x;
    // int thread_id_y = (threadIdx.x / block_dimension_x) % block_dimension_y;
    // int thread_id_z = (threadIdx.x / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += gridDim.x) {
        if (block_pos >= grid_dimension_x * grid_dimension_y * grid_dimension_z) {
            return;
        }

        int block_id_x = block_pos % grid_dimension_x;
        int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        for (int loop = 0; loop < iteration; loop++) {

            SWEEP_X = thread_id_x;
            SWEEP_Y = block_id_x;
            SWEEP_Z = block_id_y;

            //Load all of the input fields
            //This is a gather operation of the SCATTER preprocessor variable
                // is undefined in layout_config.h, or a "local" read otherwise
            tempC = SRC_C(srcGrid);
            tempN = SRC_N(srcGrid);
            tempS = SRC_S(srcGrid);
            tempE = SRC_E(srcGrid);
            tempW = SRC_W(srcGrid);
            tempT = SRC_T(srcGrid);
            tempB = SRC_B(srcGrid);
            tempNE= SRC_NE(srcGrid);
            tempNW= SRC_NW(srcGrid);
            tempSE = SRC_SE(srcGrid);
            tempSW = SRC_SW(srcGrid);
            tempNT = SRC_NT(srcGrid);
            tempNB = SRC_NB(srcGrid);
            tempST = SRC_ST(srcGrid);
            tempSB = SRC_SB(srcGrid);
            tempET = SRC_ET(srcGrid);
            tempEB = SRC_EB(srcGrid);
            tempWT = SRC_WT(srcGrid);
            tempWB = SRC_WB(srcGrid);

            //Test whether the cell is fluid or obstacle
            if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
                //Swizzle the inputs: reflect any fluid coming into this cell 
                // back to where it came from
                temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
                temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
                temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
                temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
                temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
                temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
                temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
                temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
                temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
            }
            else {
                //The math meat of LBM: ignore for optimization
                float ux, uy, uz, rho, u2;
                float temp1, temp2, temp_base;
                rho = tempC + tempN
                    + tempS + tempE
                    + tempW + tempT
                    + tempB + tempNE
                    + tempNW + tempSE
                    + tempSW + tempNT
                    + tempNB + tempST
                    + tempSB + tempET
                    + tempEB + tempWT
                    + tempWB;

                ux = + tempE - tempW
                    + tempNE - tempNW
                    + tempSE - tempSW
                    + tempET + tempEB
                    - tempWT - tempWB;
                uy = + tempN - tempS
                    + tempNE + tempNW
                    - tempSE - tempSW
                    + tempNT + tempNB
                    - tempST - tempSB;
                uz = + tempT - tempB
                    + tempNT - tempNB
                    + tempST - tempSB
                    + tempET - tempEB
                    + tempWT - tempWB;

                ux /= rho;
                uy /= rho;
                uz /= rho;
                if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                    ux = 0.005f;
                    uy = 0.002f;
                    uz = 0.000f;
                }
                u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
                temp_base = OMEGA*rho;
                temp1 = DFL1*temp_base;


                //Put the output values for this cell in the shared memory
                temp_base = OMEGA*rho;
                temp1 = DFL1*temp_base;
                temp2 = 1.0f-OMEGA;
                tempC = temp2*tempC + temp1*(                                 - u2);
                    temp1 = DFL2*temp_base;	
                tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
                tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
                tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
                tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
                tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
                tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
                temp1 = DFL3*temp_base;
                tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
                tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
                tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
                tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
                tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
                tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
                tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
                tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
                tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
                tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
                tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
                tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
            }

            //Write the results computed above
            //This is a scatter operation of the SCATTER preprocessor variable
                // is defined in layout_config.h, or a "local" write otherwise
            DST_C ( dstGrid ) = tempC;

            DST_N ( dstGrid ) = tempN; 
            DST_S ( dstGrid ) = tempS;
            DST_E ( dstGrid ) = tempE;
            DST_W ( dstGrid ) = tempW;
            DST_T ( dstGrid ) = tempT;
            DST_B ( dstGrid ) = tempB;

            DST_NE( dstGrid ) = tempNE;
            DST_NW( dstGrid ) = tempNW;
            DST_SE( dstGrid ) = tempSE;
            DST_SW( dstGrid ) = tempSW;
            DST_NT( dstGrid ) = tempNT;
            DST_NB( dstGrid ) = tempNB;
            DST_ST( dstGrid ) = tempST;
            DST_SB( dstGrid ) = tempSB;
            DST_ET( dstGrid ) = tempET;
            DST_EB( dstGrid ) = tempEB;
            DST_WT( dstGrid ) = tempWT;
            DST_WB( dstGrid ) = tempWB;
        }
    }
}


__device__ void mix_lbm( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int thread_step, int iteration) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    unsigned int block_pos = blockIdx.x;
    int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += LBM_GRID_DIM) {
        if (block_pos >= grid_dimension_x * grid_dimension_y * grid_dimension_z) {
            return;
        }

        int block_id_x = block_pos % grid_dimension_x;
        int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        for (int loop = 0; loop < iteration; loop++) {
            // float *d_temp = srcGrid;
            // srcGrid = dstGrid;
            // dstGrid = d_temp;

            SWEEP_X = thread_id_x;
            SWEEP_Y = block_id_x;
            SWEEP_Z = block_id_y;

            //Load all of the input fields
            //This is a gather operation of the SCATTER preprocessor variable
                // is undefined in layout_config.h, or a "local" read otherwise
            tempC = SRC_C(srcGrid);
            tempN = SRC_N(srcGrid);
            tempS = SRC_S(srcGrid);
            tempE = SRC_E(srcGrid);
            tempW = SRC_W(srcGrid);
            tempT = SRC_T(srcGrid);
            tempB = SRC_B(srcGrid);
            tempNE= SRC_NE(srcGrid);
            tempNW= SRC_NW(srcGrid);
            tempSE = SRC_SE(srcGrid);
            tempSW = SRC_SW(srcGrid);
            tempNT = SRC_NT(srcGrid);
            tempNB = SRC_NB(srcGrid);
            tempST = SRC_ST(srcGrid);
            tempSB = SRC_SB(srcGrid);
            tempET = SRC_ET(srcGrid);
            tempEB = SRC_EB(srcGrid);
            tempWT = SRC_WT(srcGrid);
            tempWB = SRC_WB(srcGrid);

            //Test whether the cell is fluid or obstacle
            if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
                //Swizzle the inputs: reflect any fluid coming into this cell 
                // back to where it came from
                temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
                temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
                temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
                temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
                temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
                temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
                temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
                temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
                temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
            }
            else {
                //The math meat of LBM: ignore for optimization
                float ux, uy, uz, rho, u2;
                float temp1, temp2, temp_base;
                rho = tempC + tempN
                    + tempS + tempE
                    + tempW + tempT
                    + tempB + tempNE
                    + tempNW + tempSE
                    + tempSW + tempNT
                    + tempNB + tempST
                    + tempSB + tempET
                    + tempEB + tempWT
                    + tempWB;

                ux = + tempE - tempW
                    + tempNE - tempNW
                    + tempSE - tempSW
                    + tempET + tempEB
                    - tempWT - tempWB;
                uy = + tempN - tempS
                    + tempNE + tempNW
                    - tempSE - tempSW
                    + tempNT + tempNB
                    - tempST - tempSB;
                uz = + tempT - tempB
                    + tempNT - tempNB
                    + tempST - tempSB
                    + tempET - tempEB
                    + tempWT - tempWB;

                ux /= rho;
                uy /= rho;
                uz /= rho;
                if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                    ux = 0.005f;
                    uy = 0.002f;
                    uz = 0.000f;
                }
                u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
                temp_base = OMEGA*rho;
                temp1 = DFL1*temp_base;


                //Put the output values for this cell in the shared memory
                temp_base = OMEGA*rho;
                temp1 = DFL1*temp_base;
                temp2 = 1.0f-OMEGA;
                tempC = temp2*tempC + temp1*(                                 - u2);
                    temp1 = DFL2*temp_base;	
                tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
                tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
                tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
                tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
                tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
                tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
                temp1 = DFL3*temp_base;
                tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
                tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
                tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
                tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
                tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
                tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
                tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
                tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
                tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
                tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
                tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
                tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
            }

            //Write the results computed above
            //This is a scatter operation of the SCATTER preprocessor variable
                // is defined in layout_config.h, or a "local" write otherwise
            DST_C ( dstGrid ) = tempC;

            DST_N ( dstGrid ) = tempN; 
            DST_S ( dstGrid ) = tempS;
            DST_E ( dstGrid ) = tempE;
            DST_W ( dstGrid ) = tempW;
            DST_T ( dstGrid ) = tempT;
            DST_B ( dstGrid ) = tempB;

            DST_NE( dstGrid ) = tempNE;
            DST_NW( dstGrid ) = tempNW;
            DST_SE( dstGrid ) = tempSE;
            DST_SW( dstGrid ) = tempSW;
            DST_NT( dstGrid ) = tempNT;
            DST_NB( dstGrid ) = tempNB;
            DST_ST( dstGrid ) = tempST;
            DST_SB( dstGrid ) = tempSB;
            DST_ET( dstGrid ) = tempET;
            DST_EB( dstGrid ) = tempEB;
            DST_WT( dstGrid ) = tempWT;
            DST_WB( dstGrid ) = tempWB;
        }
    }
}

__device__ void general_ptb_lbm0( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int ptb_start_block_pos, int ptb_iter_block_step, int ptb_end_block_pos, int thread_base) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    // // ori
    // int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;

    unsigned int block_pos = blockIdx.x + ptb_start_block_pos;
    int thread_id_x = (threadIdx.x - thread_base) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += ptb_iter_block_step) {
        if (block_pos >= ptb_end_block_pos) {
            return;
        }

        // ori
        // int block_id_x = block_pos % grid_dimension_x;
        // int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        int block_id_x = block_pos % grid_dimension_x;
		int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = block_pos / (grid_dimension_x * grid_dimension_y);

        // float *d_temp = srcGrid;
        // srcGrid = dstGrid;
        // dstGrid = d_temp;

        SWEEP_X = thread_id_x;
        SWEEP_Y = block_id_x;
        SWEEP_Z = block_id_y;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}


__device__ void general_ptb_lbm1( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int ptb_start_block_pos, int ptb_iter_block_step, int ptb_end_block_pos, int thread_base) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    // // ori
    // int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;

    unsigned int block_pos = blockIdx.x + ptb_start_block_pos;
    int thread_id_x = (threadIdx.x - thread_base) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += ptb_iter_block_step) {
        if (block_pos >= ptb_end_block_pos) {
            return;
        }

        // ori
        // int block_id_x = block_pos % grid_dimension_x;
        // int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        int block_id_x = block_pos % grid_dimension_x;
		int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = block_pos / (grid_dimension_x * grid_dimension_y);

        // float *d_temp = srcGrid;
        // srcGrid = dstGrid;
        // dstGrid = d_temp;

        SWEEP_X = thread_id_x;
        SWEEP_Y = block_id_x;
        SWEEP_Z = block_id_y;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}

__device__ void general_ptb_lbm2( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int ptb_start_block_pos, int ptb_iter_block_step, int ptb_end_block_pos, int thread_base) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    // // ori
    // int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;

    unsigned int block_pos = blockIdx.x + ptb_start_block_pos;
    int thread_id_x = (threadIdx.x - thread_base) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += ptb_iter_block_step) {
        if (block_pos >= ptb_end_block_pos) {
            return;
        }

        // ori
        // int block_id_x = block_pos % grid_dimension_x;
        // int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        int block_id_x = block_pos % grid_dimension_x;
		int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = block_pos / (grid_dimension_x * grid_dimension_y);

        // float *d_temp = srcGrid;
        // srcGrid = dstGrid;
        // dstGrid = d_temp;

        SWEEP_X = thread_id_x;
        SWEEP_Y = block_id_x;
        SWEEP_Z = block_id_y;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}


__device__ void general_ptb_lbm3( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int ptb_start_block_pos, int ptb_iter_block_step, int ptb_end_block_pos, int thread_base) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    // // ori
    // int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;

    unsigned int block_pos = blockIdx.x + ptb_start_block_pos;
    int thread_id_x = (threadIdx.x - thread_base) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += ptb_iter_block_step) {
        if (block_pos >= ptb_end_block_pos) {
            return;
        }

        // ori
        // int block_id_x = block_pos % grid_dimension_x;
        // int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        int block_id_x = block_pos % grid_dimension_x;
		int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = block_pos / (grid_dimension_x * grid_dimension_y);

        // float *d_temp = srcGrid;
        // srcGrid = dstGrid;
        // dstGrid = d_temp;

        SWEEP_X = thread_id_x;
        SWEEP_Y = block_id_x;
        SWEEP_Z = block_id_y;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}

__device__ void general_ptb_lbm4( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int ptb_start_block_pos, int ptb_iter_block_step, int ptb_end_block_pos, int thread_base) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    // // ori
    // int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;

    unsigned int block_pos = blockIdx.x + ptb_start_block_pos;
    int thread_id_x = (threadIdx.x - thread_base) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += ptb_iter_block_step) {
        if (block_pos >= ptb_end_block_pos) {
            return;
        }

        // ori
        // int block_id_x = block_pos % grid_dimension_x;
        // int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        int block_id_x = block_pos % grid_dimension_x;
		int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = block_pos / (grid_dimension_x * grid_dimension_y);

        // float *d_temp = srcGrid;
        // srcGrid = dstGrid;
        // dstGrid = d_temp;

        SWEEP_X = thread_id_x;
        SWEEP_Y = block_id_x;
        SWEEP_Z = block_id_y;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}

__device__ void general_ptb_lbm5( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int ptb_start_block_pos, int ptb_iter_block_step, int ptb_end_block_pos, int thread_base) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    // // ori
    // int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;

    unsigned int block_pos = blockIdx.x + ptb_start_block_pos;
    int thread_id_x = (threadIdx.x - thread_base) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += ptb_iter_block_step) {
        if (block_pos >= ptb_end_block_pos) {
            return;
        }

        // ori
        // int block_id_x = block_pos % grid_dimension_x;
        // int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        int block_id_x = block_pos % grid_dimension_x;
		int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = block_pos / (grid_dimension_x * grid_dimension_y);

        // float *d_temp = srcGrid;
        // srcGrid = dstGrid;
        // dstGrid = d_temp;

        SWEEP_X = thread_id_x;
        SWEEP_Y = block_id_x;
        SWEEP_Z = block_id_y;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}

__device__ void general_ptb_lbm6( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int ptb_start_block_pos, int ptb_iter_block_step, int ptb_end_block_pos, int thread_base) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    // // ori
    // int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;

    unsigned int block_pos = blockIdx.x + ptb_start_block_pos;
    int thread_id_x = (threadIdx.x - thread_base) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += ptb_iter_block_step) {
        if (block_pos >= ptb_end_block_pos) {
            return;
        }

        // ori
        // int block_id_x = block_pos % grid_dimension_x;
        // int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        int block_id_x = block_pos % grid_dimension_x;
		int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = block_pos / (grid_dimension_x * grid_dimension_y);

        // float *d_temp = srcGrid;
        // srcGrid = dstGrid;
        // dstGrid = d_temp;

        SWEEP_X = thread_id_x;
        SWEEP_Y = block_id_x;
        SWEEP_Z = block_id_y;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}

__device__ void general_ptb_lbm7( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int ptb_start_block_pos, int ptb_iter_block_step, int ptb_end_block_pos, int thread_base) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    // // ori
    // int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;

    unsigned int block_pos = blockIdx.x + ptb_start_block_pos;
    int thread_id_x = (threadIdx.x - thread_base) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += ptb_iter_block_step) {
        if (block_pos >= ptb_end_block_pos) {
            return;
        }

        // ori
        // int block_id_x = block_pos % grid_dimension_x;
        // int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        int block_id_x = block_pos % grid_dimension_x;
		int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = block_pos / (grid_dimension_x * grid_dimension_y);

        // float *d_temp = srcGrid;
        // srcGrid = dstGrid;
        // dstGrid = d_temp;

        SWEEP_X = thread_id_x;
        SWEEP_Y = block_id_x;
        SWEEP_Z = block_id_y;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}

__device__ void general_ptb_lbm8( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int ptb_start_block_pos, int ptb_iter_block_step, int ptb_end_block_pos, int thread_base) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    // // ori
    // int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;

    unsigned int block_pos = blockIdx.x + ptb_start_block_pos;
    int thread_id_x = (threadIdx.x - thread_base) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += ptb_iter_block_step) {
        if (block_pos >= ptb_end_block_pos) {
            return;
        }

        // ori
        // int block_id_x = block_pos % grid_dimension_x;
        // int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        int block_id_x = block_pos % grid_dimension_x;
		int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = block_pos / (grid_dimension_x * grid_dimension_y);

        // float *d_temp = srcGrid;
        // srcGrid = dstGrid;
        // dstGrid = d_temp;

        SWEEP_X = thread_id_x;
        SWEEP_Y = block_id_x;
        SWEEP_Z = block_id_y;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}

extern "C" __global__ void g_general_ptb_lbm( float* srcGrid, float* dstGrid,
    int grid_dimension_x, int grid_dimension_y, int grid_dimension_z,
    int block_dimension_x, int block_dimension_y, int block_dimension_z,
    int ptb_start_block_pos, int ptb_iter_block_step, int ptb_end_block_pos, int thread_base) {
	//Using some predefined macros here.  Consider this the declaration 
    //  and initialization of the variables SWEEP_X, SWEEP_Y and SWEEP_Z

    // // ori
    // int thread_id_x = (threadIdx.x - thread_step) % block_dimension_x;

    unsigned int block_pos = blockIdx.x + ptb_start_block_pos;
    int thread_id_x = (threadIdx.x - thread_base) % block_dimension_x;
    // int thread_id_y = ((threadIdx.x - thread_step) / block_dimension_x) % block_dimension_y;
    // int thread_id_z = ((threadIdx.x - thread_step) / block_dimension_x) / block_dimension_y;

    SWEEP_VAR
	float temp_swp, tempC, tempN, tempS, tempE, tempW, tempT, tempB;
	float tempNE, tempNW, tempSE, tempSW, tempNT, tempNB, tempST ;
	float tempSB, tempET, tempEB, tempWT, tempWB;

    for (;; block_pos += ptb_iter_block_step) {
        if (block_pos >= ptb_end_block_pos) {
            return;
        }

        // ori
        // int block_id_x = block_pos % grid_dimension_x;
        // int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = (block_pos / grid_dimension_x) / grid_dimension_y;

        int block_id_x = block_pos % grid_dimension_x;
		int block_id_y = (block_pos / grid_dimension_x) % grid_dimension_y;
        // int block_id_z = block_pos / (grid_dimension_x * grid_dimension_y);

        // float *d_temp = srcGrid;
        // srcGrid = dstGrid;
        // dstGrid = d_temp;

        SWEEP_X = thread_id_x;
        SWEEP_Y = block_id_x;
        SWEEP_Z = block_id_y;

        //Load all of the input fields
        //This is a gather operation of the SCATTER preprocessor variable
            // is undefined in layout_config.h, or a "local" read otherwise
        tempC = SRC_C(srcGrid);
        tempN = SRC_N(srcGrid);
        tempS = SRC_S(srcGrid);
        tempE = SRC_E(srcGrid);
        tempW = SRC_W(srcGrid);
        tempT = SRC_T(srcGrid);
        tempB = SRC_B(srcGrid);
        tempNE= SRC_NE(srcGrid);
        tempNW= SRC_NW(srcGrid);
        tempSE = SRC_SE(srcGrid);
        tempSW = SRC_SW(srcGrid);
        tempNT = SRC_NT(srcGrid);
        tempNB = SRC_NB(srcGrid);
        tempST = SRC_ST(srcGrid);
        tempSB = SRC_SB(srcGrid);
        tempET = SRC_ET(srcGrid);
        tempEB = SRC_EB(srcGrid);
        tempWT = SRC_WT(srcGrid);
        tempWB = SRC_WB(srcGrid);

        //Test whether the cell is fluid or obstacle
        if( TEST_FLAG_SWEEP( srcGrid, OBSTACLE )) {
            //Swizzle the inputs: reflect any fluid coming into this cell 
            // back to where it came from
            temp_swp = tempN ; tempN = tempS ; tempS = temp_swp ;
            temp_swp = tempE ; tempE = tempW ; tempW = temp_swp;
            temp_swp = tempT ; tempT = tempB ; tempB = temp_swp;
            temp_swp = tempNE; tempNE = tempSW ; tempSW = temp_swp;
            temp_swp = tempNW; tempNW = tempSE ; tempSE = temp_swp;
            temp_swp = tempNT ; tempNT = tempSB ; tempSB = temp_swp; 
            temp_swp = tempNB ; tempNB = tempST ; tempST = temp_swp;
            temp_swp = tempET ; tempET= tempWB ; tempWB = temp_swp;
            temp_swp = tempEB ; tempEB = tempWT ; tempWT = temp_swp;
        }
        else {
            //The math meat of LBM: ignore for optimization
            float ux, uy, uz, rho, u2;
            float temp1, temp2, temp_base;
            rho = tempC + tempN
                + tempS + tempE
                + tempW + tempT
                + tempB + tempNE
                + tempNW + tempSE
                + tempSW + tempNT
                + tempNB + tempST
                + tempSB + tempET
                + tempEB + tempWT
                + tempWB;

            ux = + tempE - tempW
                + tempNE - tempNW
                + tempSE - tempSW
                + tempET + tempEB
                - tempWT - tempWB;
            uy = + tempN - tempS
                + tempNE + tempNW
                - tempSE - tempSW
                + tempNT + tempNB
                - tempST - tempSB;
            uz = + tempT - tempB
                + tempNT - tempNB
                + tempST - tempSB
                + tempET - tempEB
                + tempWT - tempWB;

            ux /= rho;
            uy /= rho;
            uz /= rho;
            if( TEST_FLAG_SWEEP( srcGrid, ACCEL )) {
                ux = 0.005f;
                uy = 0.002f;
                uz = 0.000f;
            }
            u2 = 1.5f * (ux*ux + uy*uy + uz*uz) - 1.0f;
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;


            //Put the output values for this cell in the shared memory
            temp_base = OMEGA*rho;
            temp1 = DFL1*temp_base;
            temp2 = 1.0f-OMEGA;
            tempC = temp2*tempC + temp1*(                                 - u2);
                temp1 = DFL2*temp_base;	
            tempN = temp2*tempN + temp1*(       uy*(4.5f*uy       + 3.0f) - u2);
            tempS = temp2*tempS + temp1*(       uy*(4.5f*uy       - 3.0f) - u2);
            tempT = temp2*tempT + temp1*(       uz*(4.5f*uz       + 3.0f) - u2);
            tempB = temp2*tempB + temp1*(       uz*(4.5f*uz       - 3.0f) - u2);
            tempE = temp2*tempE + temp1*(       ux*(4.5f*ux       + 3.0f) - u2);
            tempW = temp2*tempW + temp1*(       ux*(4.5f*ux       - 3.0f) - u2);
            temp1 = DFL3*temp_base;
            tempNT= temp2*tempNT + temp1 *( (+uy+uz)*(4.5f*(+uy+uz) + 3.0f) - u2);
            tempNB= temp2*tempNB + temp1 *( (+uy-uz)*(4.5f*(+uy-uz) + 3.0f) - u2);
            tempST= temp2*tempST + temp1 *( (-uy+uz)*(4.5f*(-uy+uz) + 3.0f) - u2);
            tempSB= temp2*tempSB + temp1 *( (-uy-uz)*(4.5f*(-uy-uz) + 3.0f) - u2);
            tempNE = temp2*tempNE + temp1 *( (+ux+uy)*(4.5f*(+ux+uy) + 3.0f) - u2);
            tempSE = temp2*tempSE + temp1 *((+ux-uy)*(4.5f*(+ux-uy) + 3.0f) - u2);
            tempET = temp2*tempET + temp1 *( (+ux+uz)*(4.5f*(+ux+uz) + 3.0f) - u2);
            tempEB = temp2*tempEB + temp1 *( (+ux-uz)*(4.5f*(+ux-uz) + 3.0f) - u2);
            tempNW = temp2*tempNW + temp1 *( (-ux+uy)*(4.5f*(-ux+uy) + 3.0f) - u2);
            tempSW = temp2*tempSW + temp1 *( (-ux-uy)*(4.5f*(-ux-uy) + 3.0f) - u2);
            tempWT = temp2*tempWT + temp1 *( (-ux+uz)*(4.5f*(-ux+uz) + 3.0f) - u2);
            tempWB = temp2*tempWB + temp1 *( (-ux-uz)*(4.5f*(-ux-uz) + 3.0f) - u2);
        }

        //Write the results computed above
        //This is a scatter operation of the SCATTER preprocessor variable
            // is defined in layout_config.h, or a "local" write otherwise
        DST_C ( dstGrid ) = tempC;

        DST_N ( dstGrid ) = tempN; 
        DST_S ( dstGrid ) = tempS;
        DST_E ( dstGrid ) = tempE;
        DST_W ( dstGrid ) = tempW;
        DST_T ( dstGrid ) = tempT;
        DST_B ( dstGrid ) = tempB;

        DST_NE( dstGrid ) = tempNE;
        DST_NW( dstGrid ) = tempNW;
        DST_SE( dstGrid ) = tempSE;
        DST_SW( dstGrid ) = tempSW;
        DST_NT( dstGrid ) = tempNT;
        DST_NB( dstGrid ) = tempNB;
        DST_ST( dstGrid ) = tempST;
        DST_SB( dstGrid ) = tempSB;
        DST_ET( dstGrid ) = tempET;
        DST_EB( dstGrid ) = tempEB;
        DST_WT( dstGrid ) = tempWT;
        DST_WB( dstGrid ) = tempWB;
    }
}