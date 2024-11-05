classdef PlaneStress_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
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
    end

    methods (Access = private)

        function results = graph(app)
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

            end


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
        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)
            selectedButton = app.BoundaryConditionsButtonGroup.SelectedObject;
            if selectedButton.Text=="Displacement"
                app.Displacements=app.UITable.Data;
            elseif selectedButton.Text=="Force"
                app.Forces=app.UITable.Data;
            end

        end

        % Button pushed function: SolveButton
        function SolveButtonPushed(app, event)
            E = app.EEditField.Value;
            neu = app.PoissonsRatioEditField.Value;
            kGlobal = zeros(length(app.NodeCoordinates)*2);
            t = app.ThicknessEditField.Value;
            coord = app.NodeCoordinates;
            nodes = app.ElementNodes;

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
            end
            
 

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 890 498];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [485 123 375 358];

            % Create WidthEditField_2Label
            app.WidthEditField_2Label = uilabel(app.UIFigure);
            app.WidthEditField_2Label.HorizontalAlignment = 'right';
            app.WidthEditField_2Label.Position = [98 425 36 22];
            app.WidthEditField_2Label.Text = 'Width';

            % Create WidthEditField_2
            app.WidthEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.WidthEditField_2.ValueChangedFcn = createCallbackFcn(app, @WidthEditField_2ValueChanged, true);
            app.WidthEditField_2.Position = [149 425 100 22];

            % Create HeightEditFieldLabel
            app.HeightEditFieldLabel = uilabel(app.UIFigure);
            app.HeightEditFieldLabel.HorizontalAlignment = 'right';
            app.HeightEditFieldLabel.Position = [94 395 40 22];
            app.HeightEditFieldLabel.Text = 'Height';

            % Create HeightEditField
            app.HeightEditField = uieditfield(app.UIFigure, 'numeric');
            app.HeightEditField.ValueChangedFcn = createCallbackFcn(app, @HeightEditFieldValueChanged, true);
            app.HeightEditField.Position = [149 395 100 22];

            % Create HorizontalDivisionsEditFieldLabel
            app.HorizontalDivisionsEditFieldLabel = uilabel(app.UIFigure);
            app.HorizontalDivisionsEditFieldLabel.HorizontalAlignment = 'right';
            app.HorizontalDivisionsEditFieldLabel.Position = [24 294 110 22];
            app.HorizontalDivisionsEditFieldLabel.Text = 'Horizontal Divisions';

            % Create HorizontalDivisionsEditField
            app.HorizontalDivisionsEditField = uieditfield(app.UIFigure, 'numeric');
            app.HorizontalDivisionsEditField.ValueChangedFcn = createCallbackFcn(app, @HorizontalDivisionsEditFieldValueChanged, true);
            app.HorizontalDivisionsEditField.Position = [149 294 100 22];
            app.HorizontalDivisionsEditField.Value = 1;

            % Create VerticalDivisionsEditFieldLabel
            app.VerticalDivisionsEditFieldLabel = uilabel(app.UIFigure);
            app.VerticalDivisionsEditFieldLabel.HorizontalAlignment = 'right';
            app.VerticalDivisionsEditFieldLabel.Position = [38 251 96 22];
            app.VerticalDivisionsEditFieldLabel.Text = 'Vertical Divisions';

            % Create VerticalDivisionsEditField
            app.VerticalDivisionsEditField = uieditfield(app.UIFigure, 'numeric');
            app.VerticalDivisionsEditField.ValueChangedFcn = createCallbackFcn(app, @VerticalDivisionsEditFieldValueChanged, true);
            app.VerticalDivisionsEditField.Position = [149 251 100 22];
            app.VerticalDivisionsEditField.Value = 1;

            % Create PlaneDimensionsLabel
            app.PlaneDimensionsLabel = uilabel(app.UIFigure);
            app.PlaneDimensionsLabel.FontSize = 14;
            app.PlaneDimensionsLabel.FontWeight = 'bold';
            app.PlaneDimensionsLabel.Position = [24 459 126 22];
            app.PlaneDimensionsLabel.Text = 'Plane Dimensions';

            % Create MeshOptionsLabel
            app.MeshOptionsLabel = uilabel(app.UIFigure);
            app.MeshOptionsLabel.FontSize = 14;
            app.MeshOptionsLabel.FontWeight = 'bold';
            app.MeshOptionsLabel.Position = [24 332 98 22];
            app.MeshOptionsLabel.Text = 'Mesh Options';

            % Create BoundaryConditionsButtonGroup
            app.BoundaryConditionsButtonGroup = uibuttongroup(app.UIFigure);
            app.BoundaryConditionsButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @BoundaryConditionsButtonGroupSelectionChanged, true);
            app.BoundaryConditionsButtonGroup.Title = 'Boundary Conditions';
            app.BoundaryConditionsButtonGroup.Position = [282 404 176 67];

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
            app.UITable.Position = [282 161 182 233];

            % Create ProcessingLabel
            app.ProcessingLabel = uilabel(app.UIFigure);
            app.ProcessingLabel.FontSize = 14;
            app.ProcessingLabel.FontWeight = 'bold';
            app.ProcessingLabel.Position = [39 83 224 22];
            app.ProcessingLabel.Text = 'Processing';

            % Create SolveButton
            app.SolveButton = uibutton(app.UIFigure, 'push');
            app.SolveButton.ButtonPushedFcn = createCallbackFcn(app, @SolveButtonPushed, true);
            app.SolveButton.FontSize = 24;
            app.SolveButton.Position = [142 72 114 43];
            app.SolveButton.Text = 'Solve';

            % Create EEditFieldLabel
            app.EEditFieldLabel = uilabel(app.UIFigure);
            app.EEditFieldLabel.HorizontalAlignment = 'right';
            app.EEditFieldLabel.Position = [109 181 25 22];
            app.EEditFieldLabel.Text = 'E';

            % Create EEditField
            app.EEditField = uieditfield(app.UIFigure, 'numeric');
            app.EEditField.Position = [149 181 100 22];
            app.EEditField.Value = 200000000000;

            % Create PoissonsRatioEditFieldLabel
            app.PoissonsRatioEditFieldLabel = uilabel(app.UIFigure);
            app.PoissonsRatioEditFieldLabel.HorizontalAlignment = 'right';
            app.PoissonsRatioEditFieldLabel.Position = [47 149 87 22];
            app.PoissonsRatioEditFieldLabel.Text = 'Poisson''s Ratio';

            % Create PoissonsRatioEditField
            app.PoissonsRatioEditField = uieditfield(app.UIFigure, 'numeric');
            app.PoissonsRatioEditField.Position = [149 149 100 22];
            app.PoissonsRatioEditField.Value = 0.3;

            % Create ThicknessEditFieldLabel
            app.ThicknessEditFieldLabel = uilabel(app.UIFigure);
            app.ThicknessEditFieldLabel.HorizontalAlignment = 'right';
            app.ThicknessEditFieldLabel.Position = [75 362 59 22];
            app.ThicknessEditFieldLabel.Text = 'Thickness';

            % Create ThicknessEditField
            app.ThicknessEditField = uieditfield(app.UIFigure, 'numeric');
            app.ThicknessEditField.Position = [149 362 100 22];

            % Create MaterialPropertiesLabel
            app.MaterialPropertiesLabel = uilabel(app.UIFigure);
            app.MaterialPropertiesLabel.FontSize = 14;
            app.MaterialPropertiesLabel.FontWeight = 'bold';
            app.MaterialPropertiesLabel.Position = [24 216 131 22];
            app.MaterialPropertiesLabel.Text = 'Material Properties';

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