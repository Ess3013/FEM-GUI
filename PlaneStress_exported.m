classdef PlaneStress_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        KButton                        matlab.ui.control.Button
        StrainButton                   matlab.ui.control.Button
        NodesForceButton               matlab.ui.control.Button
        NodesdButton                   matlab.ui.control.Button
        StressButton                   matlab.ui.control.Button
        CornerForceButton              matlab.ui.control.Button
        ShowLabel                      matlab.ui.control.Label
        CornerdButton                  matlab.ui.control.Button
        MaterialPropertiesLabel        matlab.ui.control.Label
        ThicknessEditField             matlab.ui.control.NumericEditField
        ThicknessEditFieldLabel        matlab.ui.control.Label
        PoissonsRatioEditField         matlab.ui.control.NumericEditField
        PoissonsRatioEditFieldLabel    matlab.ui.control.Label
        EEditField                     matlab.ui.control.NumericEditField
        EEditFieldLabel                matlab.ui.control.Label
        SolveButton                    matlab.ui.control.Button
        ProcessingLabel                matlab.ui.control.Label
        UITable                        matlab.ui.control.Table
        BoundaryConditionsButtonGroup  matlab.ui.container.ButtonGroup
        ForceButton                    matlab.ui.control.ToggleButton
        DisplacementButton             matlab.ui.control.ToggleButton
        MeshOptionsLabel               matlab.ui.control.Label
        PlaneDimensionsLabel           matlab.ui.control.Label
        VerticalDivisionsEditField     matlab.ui.control.NumericEditField
        VerticalDivisionsEditFieldLabel  matlab.ui.control.Label
        HorizontalDivisionsEditField   matlab.ui.control.NumericEditField
        HorizontalDivisionsEditFieldLabel  matlab.ui.control.Label
        HeightEditField                matlab.ui.control.NumericEditField
        HeightEditFieldLabel           matlab.ui.control.Label
        WidthEditField_2               matlab.ui.control.NumericEditField
        WidthEditField_2Label          matlab.ui.control.Label
        UIAxes                         matlab.ui.control.UIAxes
    end


    properties (Access = private)
        NodeCoordinates % Description
        ElementNodes % Description
        CornerNodes % Description
        SideNodes % Description
        Displacements % Description
        Forces
        Boundary % Description
        surfForce
        poiForce
        stress % Description
        newFig1 % Description
        newFig2
        newFig3
        newFig4
        newFig5
        newFig6
        newFig7
        originalK % Description
        strain % Description
        Q % Description
        cornerD % Description
    end

    methods (Access = private)

        function results = graph(app)


            cla(app.UIAxes);
            if app.WidthEditField_2.Value~=0 && app.HeightEditField.Value~=0
                [p,cl]=GenerateMesh(app.WidthEditField_2.Value,app.HeightEditField.Value,app.HorizontalDivisionsEditField.Value,app.VerticalDivisionsEditField.Value);
                hold(app.UIAxes, 'all');
                patch(app.UIAxes,'faces', cl, 'Vertices', p, 'facecolor', 'c', 'edgecolor', 'k');
                plot(app.UIAxes,p(1,:), p(2,:), 'o', 'color', 'k');
                app.NodeCoordinates=p;
                app.ElementNodes=cl;
                %% Finding corner nodes
                app.CornerNodes=[1,
                    1+app.HorizontalDivisionsEditField.Value,
                    (1+app.HorizontalDivisionsEditField.Value)*(app.VerticalDivisionsEditField.Value+1),
                    (1+app.HorizontalDivisionsEditField.Value)*app.VerticalDivisionsEditField.Value+1];
                %End of finding corner nodes

                %% Finding Side nodes
                app.SideNodes=zeros(4,max([app.VerticalDivisionsEditField.Value+1,app.HorizontalDivisionsEditField.Value+1]));


                app.SideNodes(1,1:app.HorizontalDivisionsEditField.Value+1)=[1:(app.HorizontalDivisionsEditField.Value+1)];
                app.SideNodes(2,1:app.VerticalDivisionsEditField.Value+1)=[(1:app.VerticalDivisionsEditField.Value+1).*(app.HorizontalDivisionsEditField.Value+1)];
                app.SideNodes(3,1:app.HorizontalDivisionsEditField.Value+1)=[(1+app.HorizontalDivisionsEditField.Value)*app.VerticalDivisionsEditField.Value+1:(1+app.HorizontalDivisionsEditField.Value)*(app.VerticalDivisionsEditField.Value+1)];
                app.SideNodes(4,1:app.VerticalDivisionsEditField.Value+1)=[(1:app.VerticalDivisionsEditField.Value+1).*(app.HorizontalDivisionsEditField.Value+1)-app.HorizontalDivisionsEditField.Value];

                %End of Finding Side nodes

                app.setBoundaries();

            end


            %% Plotting Boundary conditions
            strock=max(app.WidthEditField_2.Value,app.HeightEditField.Value)/20;

            appliedForce=app.poiForce+app.surfForce;

            for dm=1:size(app.NodeCoordinates,1)
                %% Plotting Boundary conditions
                if app.Boundary(2*dm-1,1)==0
                    plot(app.UIAxes,[app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)-strock,app.NodeCoordinates(dm,1)-strock,app.NodeCoordinates(dm,1)], ...
                        [app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)+(strock/2),app.NodeCoordinates(dm,2)-(strock/2),app.NodeCoordinates(dm,2)],'Color','b');
                elseif ~isnan(app.Boundary(2*dm-1,1))
                    if app.Boundary(2*dm-1,1)>0
                        plot(app.UIAxes,[app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)+(strock/2),app.NodeCoordinates(dm,1)+strock,app.NodeCoordinates(dm,1)+1.5*strock], ...
                            [app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)+(strock/2),app.NodeCoordinates(dm,2)-(strock/2),app.NodeCoordinates(dm,2)],'Color','b');
                    else
                        plot(app.UIAxes,[app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)-(strock/2),app.NodeCoordinates(dm,1)-strock,app.NodeCoordinates(dm,1)-1.5*strock], ...
                            [app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)+(strock/2),app.NodeCoordinates(dm,2)-(strock/2),app.NodeCoordinates(dm,2)],'Color','b');
                    end
                end

                if app.Boundary(2*dm,1)==0
                    plot(app.UIAxes,[app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)+(strock/2),app.NodeCoordinates(dm,1)-(strock/2),app.NodeCoordinates(dm,1)], ...
                        [app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)-(strock),app.NodeCoordinates(dm,2)-(strock),app.NodeCoordinates(dm,2)],'Color','b');
                elseif ~isnan(app.Boundary(2*dm,1))
                    if app.Boundary(2*dm,1)>0
                        plot(app.UIAxes,[app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)+(strock/2),app.NodeCoordinates(dm,1)-(strock/2),app.NodeCoordinates(dm,1)], ...
                            [app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)+(strock/2),app.NodeCoordinates(dm,2)+(strock),app.NodeCoordinates(dm,2)+1.5*strock],'Color','b');
                    else
                        plot(app.UIAxes,[app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)+(strock/2),app.NodeCoordinates(dm,1)-(strock/2),app.NodeCoordinates(dm,1)], ...
                            [app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)-(strock/2),app.NodeCoordinates(dm,2)-(strock),app.NodeCoordinates(dm,2)-1.5*strock],'Color','b');
                    end
                end

                %% Plotting Forces

                if appliedForce(2*dm-1,1)>0
                    plot(app.UIAxes,[app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)+2*strock,app.NodeCoordinates(dm,1)+strock,app.NodeCoordinates(dm,1)+2*strock,app.NodeCoordinates(dm,1)+strock], ...
                        [app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)+0.5*strock,app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)-0.5*strock],'Color','r');
                elseif appliedForce(2*dm-1,1)<0
                    plot(app.UIAxes,[app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)-2*strock,app.NodeCoordinates(dm,1)-strock,app.NodeCoordinates(dm,1)+2*strock,app.NodeCoordinates(dm,1)-strock], ...
                        [app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)+0.5*strock,app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)-0.5*strock],'Color','r');
                end
                if appliedForce(2*dm,1)>0
                    plot(app.UIAxes,[app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)+0.5*strock,app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)-0.5*strock], ...
                        [app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)+2*strock,app.NodeCoordinates(dm,2)+strock,app.NodeCoordinates(dm,2)+2*strock,app.NodeCoordinates(dm,2)+strock],'Color','r');
                elseif appliedForce(2*dm,1)<0
                    plot(app.UIAxes,[app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)+0.5*strock,app.NodeCoordinates(dm,1),app.NodeCoordinates(dm,1)-0.5*strock], ...
                        [app.NodeCoordinates(dm,2),app.NodeCoordinates(dm,2)-2*strock,app.NodeCoordinates(dm,2)-strock,app.NodeCoordinates(dm,2)-2*strock,app.NodeCoordinates(dm,2)-strock],'Color','r');
                end

            end

            pbaspect(app.UIAxes, [1 1 1]);
        end

        function results = setBoundaries(app)

            t = app.ThicknessEditField.Value;
            coord = app.NodeCoordinates;
            nodes = app.ElementNodes;
            hDiv=app.HorizontalDivisionsEditField.Value;
            vDiv=app.VerticalDivisionsEditField.Value;
            width=app.WidthEditField_2.Value;
            height=app.HeightEditField.Value;


            %% Force Matrix
            % Point Loads
            pointForce=zeros(size(coord,1)*2,1);

            pointForce(app.CornerNodes(1:4)*2-1,1)=app.Forces(1:4,1);
            pointForce(app.CornerNodes(1:4)*2,1)=app.Forces(1:4,2);

            app.poiForce=pointForce;

            %Surface Loads
            surfaceForce=zeros(size(coord,1)*2,1);
            surfaceForce([app.SideNodes(1,1:hDiv+1)*2-1],1)=surfaceForce([app.SideNodes(1,1:hDiv+1)*2-1],1)+(app.Forces(5,1)*width*t)/(hDiv+1);
            surfaceForce([app.SideNodes(1,1:hDiv+1)*2],1)=surfaceForce([app.SideNodes(1,1:hDiv+1)*2],1)+(app.Forces(5,2)*width*t)/(hDiv+1);
            surfaceForce([app.SideNodes(2,1:vDiv+1)*2-1],1)=surfaceForce([app.SideNodes(2,1:vDiv+1)*2-1],1)+(app.Forces(6,1)*height*t)/(vDiv+1);
            surfaceForce([app.SideNodes(2,1:vDiv+1)*2],1)=surfaceForce([app.SideNodes(2,1:vDiv+1)*2],1)+(app.Forces(6,2)*height*t)/(vDiv+1);
            surfaceForce([app.SideNodes(3,1:hDiv+1)*2-1],1)=surfaceForce([app.SideNodes(3,1:hDiv+1)*2-1],1)+(app.Forces(7,1)*width*t)/(hDiv+1);
            surfaceForce([app.SideNodes(3,1:hDiv+1)*2],1)=surfaceForce([app.SideNodes(3,1:hDiv+1)*2],1)+(app.Forces(7,2)*width*t)/(hDiv+1);
            surfaceForce([app.SideNodes(4,1:vDiv+1)*2-1],1)=surfaceForce([app.SideNodes(4,1:vDiv+1)*2-1],1)+(app.Forces(8,1)*height*t)/(vDiv+1);
            surfaceForce([app.SideNodes(4,1:vDiv+1)*2],1)=surfaceForce([app.SideNodes(4,1:vDiv+1)*2],1)+(app.Forces(8,2)*height*t)/(vDiv+1);

            app.surfForce=surfaceForce;
            %Body Loads


            totalForce=pointForce+surfaceForce;


            %% Boundary Conditions
            boundaries=NaN(size(coord,1)*2,1);



            for dm=1:hDiv+1
                if ~isnan(app.Displacements(5,1))
                    boundaries([app.SideNodes(1,1:hDiv+1)*2-1],1)=app.Displacements(5,1);
                end
                if ~isnan(app.Displacements(5,2))
                    boundaries([app.SideNodes(1,1:hDiv+1)*2],1)=app.Displacements(5,2);
                end
                if ~isnan(app.Displacements(7,1))
                    boundaries([app.SideNodes(3,1:hDiv+1)*2-1],1)=app.Displacements(7,1);
                end
                if ~isnan(app.Displacements(7,2))

                    boundaries([app.SideNodes(3,1:hDiv+1)*2],1)=app.Displacements(7,2);
                end
            end


            for dm=1:vDiv+1

                if ~isnan(app.Displacements(6,1))
                    boundaries([app.SideNodes(2,1:vDiv+1)*2-1],1)= app.Displacements(6,1);
                end
                if ~isnan(app.Displacements(6,2))
                    boundaries([app.SideNodes(2,1:vDiv+1)*2],1)=app.Displacements(6,2);
                end
                if ~isnan(app.Displacements(8,1))

                    boundaries([app.SideNodes(4,1:vDiv+1)*2-1],1)=app.Displacements(8,1);
                end
                if ~isnan(app.Displacements(8,2))
                    boundaries([app.SideNodes(4,1:vDiv+1)*2],1)=app.Displacements(8,2);
                end

            end

            for dm=1:4
                if ~isnan(app.Displacements(dm,1))
                    boundaries(app.CornerNodes(dm)*2-1,1)=app.Displacements(dm,1);
                end
                if ~isnan(app.Displacements(dm,2))

                    boundaries(app.CornerNodes(dm)*2,1)=app.Displacements(dm,2);
                end
            end

            app.Boundary=boundaries;

        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.ProcessingLabel.Text="Processing...";
            app.Displacements=NaN(8,2);
            app.Forces=zeros(8,2);
            app.UITable.Data=app.Displacements;
            app.ProcessingLabel.Text="Ready for inputs";
        end

        % Value changed function: WidthEditField_2
        function WidthEditField_2ValueChanged(app, event)
            value = app.WidthEditField_2.Value;
            app.graph();
        end

        % Value changed function: HeightEditField
        function HeightEditFieldValueChanged(app, event)
            value = app.HeightEditField.Value;
            app.graph();
        end

        % Value changed function: HorizontalDivisionsEditField
        function HorizontalDivisionsEditFieldValueChanged(app, event)
            value = app.HorizontalDivisionsEditField.Value;
            app.graph();
        end

        % Value changed function: VerticalDivisionsEditField
        function VerticalDivisionsEditFieldValueChanged(app, event)
            value = app.VerticalDivisionsEditField.Value;
            app.graph();
        end

        % Selection changed function: BoundaryConditionsButtonGroup
        function BoundaryConditionsButtonGroupSelectionChanged(app, event)
            selectedButton = app.BoundaryConditionsButtonGroup.SelectedObject;

            if selectedButton.Text=="Displacement"
                app.UITable.Data=app.Displacements;
            elseif selectedButton.Text=="Force"
                app.UITable.Data=app.Forces;
            end
            app.graph()
        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)
            selectedButton = app.BoundaryConditionsButtonGroup.SelectedObject;

            if selectedButton.Text=="Displacement"
                app.Displacements=app.UITable.Data;

            elseif selectedButton.Text=="Force"
                app.Forces=app.UITable.Data;

            end
            app.graph()

        end

        % Button pushed function: SolveButton
        function SolveButtonPushed(app, event)
            app.ProcessingLabel.Text="Solving ...";
            E = app.EEditField.Value;
            neu = app.PoissonsRatioEditField.Value;
            kGlobal = zeros(length(app.NodeCoordinates)*2);
            t = app.ThicknessEditField.Value;
            coord = app.NodeCoordinates;
            nodes = app.ElementNodes;
            hDiv=app.HorizontalDivisionsEditField.Value;
            vDiv=app.VerticalDivisionsEditField.Value;
            width=app.WidthEditField_2.Value;
            height=app.HeightEditField.Value;

            %Plane Stress

            %% Calculating D
            D = E / (1-neu^2) * [1 neu 0;
                neu 1 0;
                0 0 (1-neu)/2];
            %%

            % Calculating kGlobal
            % For each element
            for index = 1:size(app.ElementNodes,1)
                %% Calculating Area
                A = (coord(nodes(index,1),1)*(coord(nodes(index,2),2)-coord(nodes(index,3),2)) ...
                    +coord(nodes(index,2),1)*(coord(nodes(index,3),2)-coord(nodes(index,1),2)) ...
                    +coord(nodes(index,3),1)*(coord(nodes(index,1),2)-coord(nodes(index,2),2)))/2;

                %% Calculating B using beta and gamma
                beta = [coord(nodes(index,2),2) - coord(nodes(index,3),2),
                    coord(nodes(index,3),2) - coord(nodes(index,1),2),
                    coord(nodes(index,1),2) - coord(nodes(index,2),2)];
                gamma = [coord(nodes(index,3),1) - coord(nodes(index,2),1),
                    coord(nodes(index,1),1) - coord(nodes(index,3),1),
                    coord(nodes(index,2),1) - coord(nodes(index,1),1)];
                B = (1/(2*A)) * [beta(1) 0 beta(2) 0 beta(3) 0;
                    0 gamma(1) 0 gamma(2) 0 gamma(3);
                    gamma(1) beta(1) gamma(2) beta(2) gamma(3) beta(3)];

                %% Calculating local k
                k = t*A*B'*D*B;

                %% kGlobal assembly
                % Rows 1:2 with columns 1:6
                kGlobal((nodes(index,1)*2)-1:nodes(index,1)*2, (nodes(index,1)*2)-1:nodes(index,1)*2)=...
                    kGlobal((nodes(index,1)*2)-1:nodes(index,1)*2, (nodes(index,1)*2)-1:nodes(index,1)*2)...
                    +k(1:2,1:2);
                kGlobal((nodes(index,1)*2)-1:nodes(index,1)*2, (nodes(index,2)*2)-1:nodes(index,2)*2)=...
                    kGlobal((nodes(index,1)*2)-1:nodes(index,1)*2, (nodes(index,2)*2)-1:nodes(index,2)*2)...
                    +k(1:2,3:4);
                kGlobal((nodes(index,1)*2)-1:nodes(index,1)*2, (nodes(index,3)*2)-1:nodes(index,3)*2)=...
                    kGlobal((nodes(index,1)*2)-1:nodes(index,1)*2, (nodes(index,3)*2)-1:nodes(index,3)*2)...
                    +k(1:2,5:6);

                % Rows 3:4 with columns 1:6
                kGlobal((nodes(index,2)*2)-1:nodes(index,2)*2, (nodes(index,1)*2)-1:nodes(index,1)*2)=...
                    kGlobal((nodes(index,2)*2)-1:nodes(index,2)*2, (nodes(index,1)*2)-1:nodes(index,1)*2)...
                    +k(3:4,1:2);
                kGlobal((nodes(index,2)*2)-1:nodes(index,2)*2, (nodes(index,2)*2)-1:nodes(index,2)*2)=...
                    kGlobal((nodes(index,2)*2)-1:nodes(index,2)*2, (nodes(index,2)*2)-1:nodes(index,2)*2)...
                    +k(3:4,3:4);
                kGlobal((nodes(index,2)*2)-1:nodes(index,2)*2, (nodes(index,3)*2)-1:nodes(index,3)*2)=...
                    kGlobal((nodes(index,2)*2)-1:nodes(index,2)*2, (nodes(index,3)*2)-1:nodes(index,3)*2)...
                    +k(3:4,5:6);

                % Rows 5:6 with columns 1:6
                kGlobal((nodes(index,3)*2)-1:nodes(index,3)*2, (nodes(index,1)*2)-1:nodes(index,1)*2)=...
                    kGlobal((nodes(index,3)*2)-1:nodes(index,3)*2, (nodes(index,1)*2)-1:nodes(index,1)*2)...
                    +k(5:6,1:2);
                kGlobal((nodes(index,3)*2)-1:nodes(index,3)*2, (nodes(index,2)*2)-1:nodes(index,2)*2)=...
                    kGlobal((nodes(index,3)*2)-1:nodes(index,3)*2, (nodes(index,2)*2)-1:nodes(index,2)*2)...
                    +k(5:6,3:4);
                kGlobal((nodes(index,3)*2)-1:nodes(index,3)*2, (nodes(index,3)*2)-1:nodes(index,3)*2)=...
                    kGlobal((nodes(index,3)*2)-1:nodes(index,3)*2, (nodes(index,3)*2)-1:nodes(index,3)*2)...
                    +k(5:6,5:6);
                %% End of kGlobal Assembly
                app.originalK=kGlobal;




            end


            app.setBoundaries();
            boundaries=app.Boundary;
            pointForce=app.poiForce;
            surfaceForce=app.surfForce;
            totalForce=pointForce+surfaceForce;

            %% Solve
            c=max(abs(diag(kGlobal)))*1e6  ;

            for dm=1:size(boundaries,1)

                if ~isnan(boundaries(dm))

                    kGlobal(dm,dm)=kGlobal(dm,dm)+c;
                    totalForce(dm,1)=totalForce(dm,1)+c*boundaries(dm);
                end
            end
            Q=kGlobal\totalForce;
            %% Calculating Stresses

            for index=1:size(app.ElementNodes,1)
                elementDisplacement=[Q(app.ElementNodes(index,1)*2-1,1);Q(app.ElementNodes(index,1)*2,1);...
                    Q(app.ElementNodes(index,2)*2-1,1);Q(app.ElementNodes(index,2)*2,1);...
                    Q(app.ElementNodes(index,3)*2-1,1);Q(app.ElementNodes(index,3)*2,1)];
                D = E / (1-neu^2) * [1 neu 0;
                    neu 1 0;
                    0 0 (1-neu)/2];
                beta = [coord(nodes(index,2),2) - coord(nodes(index,3),2),
                    coord(nodes(index,3),2) - coord(nodes(index,1),2),
                    coord(nodes(index,1),2) - coord(nodes(index,2),2)];
                gamma = [coord(nodes(index,3),1) - coord(nodes(index,2),1),
                    coord(nodes(index,1),1) - coord(nodes(index,3),1),
                    coord(nodes(index,2),1) - coord(nodes(index,1),1)];
                B = (1/(2*A)) * [beta(1) 0 beta(2) 0 beta(3) 0;
                    0 gamma(1) 0 gamma(2) 0 gamma(3);
                    gamma(1) beta(1) gamma(2) beta(2) gamma(3) beta(3)];
                app.stress(index,:)=[D*B*elementDisplacement]';

                 %% Calculating Strain

                app.strain(index,:)=[B*elementDisplacement]';
                
            end
            format long
               


           
            



            %% enabling buttons
            app.CornerdButton.Enable="on";
            app.NodesdButton.Enable="on";
            app.StressButton.Enable="on";
            app.StrainButton.Enable="on";
            app.CornerForceButton.Enable="on";
            app.NodesForceButton.Enable="on";
            app.KButton.Enable="on";
            %% Preparing Q
            app.Q=[Q(((1:size(app.NodeCoordinates,1))*2-1),1),Q(((1:size(app.NodeCoordinates,1))*2),1)];
            app.cornerD=[Q(app.CornerNodes*2-1,1),Q(app.CornerNodes*2,1)];
            




            app.graph();


            

            app.ProcessingLabel.Text="Ready for Input";
        end

        % Value changed function: ThicknessEditField
        function ThicknessEditFieldValueChanged(app, event)
            value = app.ThicknessEditField.Value;
            app.graph();
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete(app)
            if isvalid(app.newFig1)
                close(app.newFig1);
            end
        end

        % Button pushed function: StressButton
        function StressButtonPushed(app, event)
            app.newFig1 = uifigure('Name', 'Stresses', 'Position', [100, 200, 650, 600]);
            uit = uitable(app.newFig1,'Position', [50, 50, 550, 550]);
            uit.ColumnName = {'Stress in X', 'Stress in Y','Shear XY'};
            uit.Data = app.stress;
        end

        % Button pushed function: KButton
        function KButtonPushed(app, event)
            app.newFig2 = uifigure('Name', 'Stiffness Matrix', 'Position', [100, 200, 650, 600]);
            uit = uitable(app.newFig2,'Position', [50, 50, 550, 550]);
            uit.Data = app.originalK;
        end

        % Button pushed function: StrainButton
        function StrainButtonPushed(app, event)
            app.newFig3 = uifigure('Name', 'Stresses', 'Position', [100, 200, 650, 600]);
            uit = uitable(app.newFig3,'Position', [50, 50, 550, 550]);
            uit.ColumnName = {'Strain in X', 'Strain in Y','Angle Strain XY'};
            uit.Data = app.strain;
        end

        % Button pushed function: NodesdButton
        function NodesdButtonPushed(app, event)
            app.newFig4 = uifigure('Name', 'Stresses', 'Position', [100, 200, 650, 600]);
            uit = uitable(app.newFig4,'Position', [50, 50, 550, 550]);
            uit.ColumnName = {'X', 'Y'};
            uit.Data = app.Q;
        end

        % Button pushed function: CornerdButton
        function CornerdButtonPushed(app, event)
             app.newFig5 = uifigure('Name', 'Stresses', 'Position', [100, 200, 650, 600]);
            uit = uitable(app.newFig5,'Position', [50, 50, 550, 550]);
            uit.ColumnName = {'X', 'Y'};
            uit.Data = app.cornerD;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 890 513];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [485 138 375 358];

            % Create WidthEditField_2Label
            app.WidthEditField_2Label = uilabel(app.UIFigure);
            app.WidthEditField_2Label.HorizontalAlignment = 'right';
            app.WidthEditField_2Label.Position = [98 440 36 22];
            app.WidthEditField_2Label.Text = 'Width';

            % Create WidthEditField_2
            app.WidthEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.WidthEditField_2.ValueChangedFcn = createCallbackFcn(app, @WidthEditField_2ValueChanged, true);
            app.WidthEditField_2.Position = [149 440 100 22];

            % Create HeightEditFieldLabel
            app.HeightEditFieldLabel = uilabel(app.UIFigure);
            app.HeightEditFieldLabel.HorizontalAlignment = 'right';
            app.HeightEditFieldLabel.Position = [94 410 40 22];
            app.HeightEditFieldLabel.Text = 'Height';

            % Create HeightEditField
            app.HeightEditField = uieditfield(app.UIFigure, 'numeric');
            app.HeightEditField.ValueChangedFcn = createCallbackFcn(app, @HeightEditFieldValueChanged, true);
            app.HeightEditField.Position = [149 410 100 22];

            % Create HorizontalDivisionsEditFieldLabel
            app.HorizontalDivisionsEditFieldLabel = uilabel(app.UIFigure);
            app.HorizontalDivisionsEditFieldLabel.HorizontalAlignment = 'right';
            app.HorizontalDivisionsEditFieldLabel.Position = [24 309 110 22];
            app.HorizontalDivisionsEditFieldLabel.Text = 'Horizontal Divisions';

            % Create HorizontalDivisionsEditField
            app.HorizontalDivisionsEditField = uieditfield(app.UIFigure, 'numeric');
            app.HorizontalDivisionsEditField.ValueChangedFcn = createCallbackFcn(app, @HorizontalDivisionsEditFieldValueChanged, true);
            app.HorizontalDivisionsEditField.Position = [149 309 100 22];
            app.HorizontalDivisionsEditField.Value = 1;

            % Create VerticalDivisionsEditFieldLabel
            app.VerticalDivisionsEditFieldLabel = uilabel(app.UIFigure);
            app.VerticalDivisionsEditFieldLabel.HorizontalAlignment = 'right';
            app.VerticalDivisionsEditFieldLabel.Position = [38 266 96 22];
            app.VerticalDivisionsEditFieldLabel.Text = 'Vertical Divisions';

            % Create VerticalDivisionsEditField
            app.VerticalDivisionsEditField = uieditfield(app.UIFigure, 'numeric');
            app.VerticalDivisionsEditField.ValueChangedFcn = createCallbackFcn(app, @VerticalDivisionsEditFieldValueChanged, true);
            app.VerticalDivisionsEditField.Position = [149 266 100 22];
            app.VerticalDivisionsEditField.Value = 1;

            % Create PlaneDimensionsLabel
            app.PlaneDimensionsLabel = uilabel(app.UIFigure);
            app.PlaneDimensionsLabel.FontSize = 14;
            app.PlaneDimensionsLabel.FontWeight = 'bold';
            app.PlaneDimensionsLabel.Position = [24 474 126 22];
            app.PlaneDimensionsLabel.Text = 'Plane Dimensions';

            % Create MeshOptionsLabel
            app.MeshOptionsLabel = uilabel(app.UIFigure);
            app.MeshOptionsLabel.FontSize = 14;
            app.MeshOptionsLabel.FontWeight = 'bold';
            app.MeshOptionsLabel.Position = [24 347 98 22];
            app.MeshOptionsLabel.Text = 'Mesh Options';

            % Create BoundaryConditionsButtonGroup
            app.BoundaryConditionsButtonGroup = uibuttongroup(app.UIFigure);
            app.BoundaryConditionsButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @BoundaryConditionsButtonGroupSelectionChanged, true);
            app.BoundaryConditionsButtonGroup.Title = 'Boundary Conditions';
            app.BoundaryConditionsButtonGroup.Position = [282 419 176 67];

            % Create DisplacementButton
            app.DisplacementButton = uitogglebutton(app.BoundaryConditionsButtonGroup);
            app.DisplacementButton.Text = 'Displacement';
            app.DisplacementButton.Position = [10 13 88 23];
            app.DisplacementButton.Value = true;

            % Create ForceButton
            app.ForceButton = uitogglebutton(app.BoundaryConditionsButtonGroup);
            app.ForceButton.Text = 'Force';
            app.ForceButton.Position = [113 13 56 23];

            % Create UITable
            app.UITable = uitable(app.UIFigure);
            app.UITable.ColumnName = {'x'; 'y'};
            app.UITable.ColumnWidth = {65, 65};
            app.UITable.RowName = {'Node 1'; 'Node 2'; 'Node 3'; 'Node 4'; 'Side 1'; 'Side 2'; 'Side 3'; 'Side 4'};
            app.UITable.ColumnEditable = true;
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.Position = [282 176 182 233];

            % Create ProcessingLabel
            app.ProcessingLabel = uilabel(app.UIFigure);
            app.ProcessingLabel.FontSize = 14;
            app.ProcessingLabel.FontWeight = 'bold';
            app.ProcessingLabel.Position = [33 97 224 22];
            app.ProcessingLabel.Text = 'Processing';

            % Create SolveButton
            app.SolveButton = uibutton(app.UIFigure, 'push');
            app.SolveButton.ButtonPushedFcn = createCallbackFcn(app, @SolveButtonPushed, true);
            app.SolveButton.FontSize = 24;
            app.SolveButton.Position = [180 87 114 43];
            app.SolveButton.Text = 'Solve';

            % Create EEditFieldLabel
            app.EEditFieldLabel = uilabel(app.UIFigure);
            app.EEditFieldLabel.HorizontalAlignment = 'right';
            app.EEditFieldLabel.Position = [109 196 25 22];
            app.EEditFieldLabel.Text = 'E';

            % Create EEditField
            app.EEditField = uieditfield(app.UIFigure, 'numeric');
            app.EEditField.Position = [149 196 100 22];
            app.EEditField.Value = 200000000000;

            % Create PoissonsRatioEditFieldLabel
            app.PoissonsRatioEditFieldLabel = uilabel(app.UIFigure);
            app.PoissonsRatioEditFieldLabel.HorizontalAlignment = 'right';
            app.PoissonsRatioEditFieldLabel.Position = [47 164 87 22];
            app.PoissonsRatioEditFieldLabel.Text = 'Poisson''s Ratio';

            % Create PoissonsRatioEditField
            app.PoissonsRatioEditField = uieditfield(app.UIFigure, 'numeric');
            app.PoissonsRatioEditField.Position = [149 164 100 22];
            app.PoissonsRatioEditField.Value = 0.3;

            % Create ThicknessEditFieldLabel
            app.ThicknessEditFieldLabel = uilabel(app.UIFigure);
            app.ThicknessEditFieldLabel.HorizontalAlignment = 'right';
            app.ThicknessEditFieldLabel.Position = [75 377 59 22];
            app.ThicknessEditFieldLabel.Text = 'Thickness';

            % Create ThicknessEditField
            app.ThicknessEditField = uieditfield(app.UIFigure, 'numeric');
            app.ThicknessEditField.ValueChangedFcn = createCallbackFcn(app, @ThicknessEditFieldValueChanged, true);
            app.ThicknessEditField.Position = [149 377 100 22];

            % Create MaterialPropertiesLabel
            app.MaterialPropertiesLabel = uilabel(app.UIFigure);
            app.MaterialPropertiesLabel.FontSize = 14;
            app.MaterialPropertiesLabel.FontWeight = 'bold';
            app.MaterialPropertiesLabel.Position = [24 231 131 22];
            app.MaterialPropertiesLabel.Text = 'Material Properties';

            % Create CornerdButton
            app.CornerdButton = uibutton(app.UIFigure, 'push');
            app.CornerdButton.ButtonPushedFcn = createCallbackFcn(app, @CornerdButtonPushed, true);
            app.CornerdButton.Enable = 'off';
            app.CornerdButton.Position = [98 48 100 23];
            app.CornerdButton.Text = 'Corner d';

            % Create ShowLabel
            app.ShowLabel = uilabel(app.UIFigure);
            app.ShowLabel.Position = [24 48 35 22];
            app.ShowLabel.Text = 'Show';

            % Create CornerForceButton
            app.CornerForceButton = uibutton(app.UIFigure, 'push');
            app.CornerForceButton.Enable = 'off';
            app.CornerForceButton.Position = [216 48 100 23];
            app.CornerForceButton.Text = 'Corner Force';

            % Create StressButton
            app.StressButton = uibutton(app.UIFigure, 'push');
            app.StressButton.ButtonPushedFcn = createCallbackFcn(app, @StressButtonPushed, true);
            app.StressButton.Enable = 'off';
            app.StressButton.Position = [338 48 100 23];
            app.StressButton.Text = 'Stress';

            % Create NodesdButton
            app.NodesdButton = uibutton(app.UIFigure, 'push');
            app.NodesdButton.ButtonPushedFcn = createCallbackFcn(app, @NodesdButtonPushed, true);
            app.NodesdButton.Enable = 'off';
            app.NodesdButton.Position = [98 13 100 23];
            app.NodesdButton.Text = 'Nodes d';

            % Create NodesForceButton
            app.NodesForceButton = uibutton(app.UIFigure, 'push');
            app.NodesForceButton.Enable = 'off';
            app.NodesForceButton.Position = [216 13 100 23];
            app.NodesForceButton.Text = 'Nodes Force';

            % Create StrainButton
            app.StrainButton = uibutton(app.UIFigure, 'push');
            app.StrainButton.ButtonPushedFcn = createCallbackFcn(app, @StrainButtonPushed, true);
            app.StrainButton.Enable = 'off';
            app.StrainButton.Position = [338 13 100 23];
            app.StrainButton.Text = 'Strain';

            % Create KButton
            app.KButton = uibutton(app.UIFigure, 'push');
            app.KButton.ButtonPushedFcn = createCallbackFcn(app, @KButtonPushed, true);
            app.KButton.Enable = 'off';
            app.KButton.Position = [450 26 100 23];
            app.KButton.Text = 'K';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = PlaneStress_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end